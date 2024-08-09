// https://chatgpt.com/share/6dbed696-9f8c-475e-92b1-4f85bf5fe0a5
// https://github.com/orgs/supabase/discussions/15961
// https://flutterflowvip.notion.site/OneSignal-Supabase-Integration-5121b124665341b2b7cfc9beaf05dc99

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
    const bigPicture = record["bigPicture"] ||
      "https://example.com/default-image.jpg";

    // Construct the OneSignal notification body using the parsed payload data
    const oneSignalBody = {
      app_id: _OnesignalAppId_, // Set the OneSignal app ID
      included_segments: ["Total Subscriptions"], // Target all subscribed users
      contents: {
        en: content, // Set the notification content in English
      },
      headings: {
        en: title, // Set the notification title in English
      },
      big_picture: bigPicture, // Include a large image in the notification, or use a default image
      name: "INTERNAL_CAMPAIGN_NAME", // Set the internal campaign name for tracking
      data: {
        type: record.type, // Pass additional data, such as the type of notification
        table: record.table, // Include the table reference if applicable
        record: record.record, // Include the record data from the payload
      },
    };

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

    // Uncomment the following line if you prefer to use the OneSignal SDK directly to send notifications
    // const onesignalApiRes = await onesignal.createNotification(notification);
    // This method is currently commented out in favor of using fetch, which allows for more control over the HTTP request,
    // such as adding custom headers or handling the response in a specific way. The SDK method is simpler but abstracts
    // away some of the details that might be necessary in more complex scenarios.
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
