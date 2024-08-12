// https://chatgpt.com/share/6dbed696-9f8c-475e-92b1-4f85bf5fe0a5
// https://github.com/orgs/supabase/discussions/15961
// https://flutterflowvip.notion.site/OneSignal-Supabase-Integration-5121b124665341b2b7cfc9beaf05dc99

// supabase/functions/notificationHandler/index.ts

// Import necessary modules
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { _OnesignalAppId_, _OnesignalRestApiKey_ } from "../_utils/config.ts";

// Initialize the server to handle incoming requests
serve(async (req) => {
  try {
    // Parse the incoming JSON payload from the request
    const payload = await req.json();
    console.log("Received payload:", JSON.stringify(payload, null, 2));

    // Extract the 'record' object from the payload
    const { record } = payload;

    // Validate that the 'record' object and its essential properties exist
    if (!record || !record.title || !record.content) {
      console.error(
        "Invalid payload: 'record', 'title', or 'content' is undefined",
      );
      return new Response(
        JSON.stringify({
          error:
            "Invalid payload: 'record', 'title', or 'content' is undefined",
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 400,
        },
      );
    }

    // Define notification parameters, using defaults if specific values are missing
    const title = record.title || "New Notification";
    const content = record.content || "This is a new notification";
    const bigPicture = record.big_picture ||
      "https://example.com/default-image.jpg";
    const thumbnail = record.thumbnail || ""; // Small icon or thumbnail image
    const url = record.url || ""; // URL or deep link for the notification
    const groupId = record.group_id || null; // Group ID if applicable
    const sendTime = record.send_time
      ? new Date(record.send_time).toISOString()
      : null; // Scheduled send time
    const expirationTime = record.expiration_time
      ? new Date(record.expiration_time).toISOString()
      : null; // Expiration time

    // Construct the OneSignal notification body using the parsed payload data
    const oneSignalBody: any = {
      app_id: _OnesignalAppId_, // Set the OneSignal app ID
      contents: {
        en: content, // Set the notification content in English
      },
      headings: {
        en: title, // Set the notification title in English
      },
      big_picture: bigPicture, // Include a large image in the notification, or use a default image
      small_icon: thumbnail, // Set the small icon or thumbnail
      url: url, // Include a URL or deep link
      name: record.campaign_name || "INTERNAL_CAMPAIGN_NAME", // Set the internal campaign name for tracking
      data: {
        type: record.type, // Pass additional data, such as the type of notification
        category: record.category, // Include the notification category
        table: record.table, // Include the table reference if applicable
        record: record.record, // Include the record data from the payload
      },
    };

    // Include send time and expiration time if defined
    if (sendTime) {
      oneSignalBody.send_after = sendTime;
    }

    if (expirationTime) {
      oneSignalBody.expiration_time = expirationTime;
    }

    // Handle targeting based on the user_id or group_id
    if (record.user_id) {
      oneSignalBody.include_external_user_ids = [record.user_id]; // Target a specific user
    } else if (groupId) {
      oneSignalBody.included_segments = [`Group_${groupId}`]; // Target a specific group
    } else {
      oneSignalBody.included_segments = ["Total Subscriptions"]; // Target all subscribed users
    }

    // Set priority if it's provided
    if (record.priority) {
      oneSignalBody.priority = record.priority; // Set notification priority
    }

    // Set the status if it's provided
    if (record.status) {
      oneSignalBody.status = record.status; // Set the initial status of the notification
    }

    // Attempt to send the notification to OneSignal using the constructed body
    try {
      const response = await fetch(
        "https://onesignal.com/api/v1/notifications",
        {
          method: "POST", // Specify the HTTP method as POST
          headers: {
            "Content-Type": "application/json", // Set the content type as JSON
            "Authorization": `Basic ${_OnesignalRestApiKey_}`, // Include the OneSignal REST API key for authorization
          },
          body: JSON.stringify(oneSignalBody), // Convert the notification body to JSON and include it in the request
        },
      );

      // Parse the response from OneSignal
      const responseData = await response.json();
      console.log("OneSignal API Response:", responseData);

      // Return a success response with the OneSignal API response data
      const data = {
        message: "Payload received successfully",
        oneSignalResponse: responseData,
      };

      return new Response(
        JSON.stringify(data),
        { headers: { "Content-Type": "application/json" } },
      );
    } catch (error) {
      // Log any errors that occur during the API request to OneSignal
      console.error("Error making OneSignal API request:", error);

      // Return an error response if the request to OneSignal fails
      const errorMessage = {
        error: "Failed to send notification to OneSignal",
      };

      return new Response(
        JSON.stringify(errorMessage),
        { headers: { "Content-Type": "application/json" }, status: 500 },
      );
    }
  } catch (err) {
    // Log any errors that occur during the initial handling of the request
    console.error("Failed to create OneSignal notification", err);

    // Return an error response if the initial processing fails
    return new Response("Server error.", {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
