import amqp from "amqplib";
import Ably from 'ably';
import axios from 'axios';
import figlet from 'figlet';

const url = 'amqps://HKx6dw.e3Icdw:jkBIoji6u84OS6CHfiiPHFfOcHjJcydTSsqs50IiCVI@us-east-1-a-queue.ably.io/shared';
const ably = new Ably.Realtime('wx4sNQ.gLYtJg:5FhBJjeC9wGYfNDTZiIznwEbZNP32FTayD0EQ0R9ZlQ');

let connection, channel;

async function createChannel(conn) {
  console.log('Creating channel...');
  const ch = await conn.createChannel();
  ch.on('close', async () => {
    console.log('Channel closed, reconnecting...');
    await connectToQueue();
  });
  console.log('Channel created successfully');
  return ch;
}

async function connectToQueue() {
  console.log('Connecting to AMQP server...');
  try {
    connection = await amqp.connect(url);
    console.log('Connected to AMQP server');

    connection.on('close', async () => {
      console.log('Connection closed, reconnecting...');
      await connectToQueue();
    });

    connection.on('error', async (err) => {
      console.error('Connection error:', err);
      await connectToQueue();
    });

    channel = await createChannel(connection);
    console.log('Consuming messages from queue...');
    await channel.consume('HKx6dw:ImageRequests', async (item) => {
      console.log('Message received from queue');
      let decodedEnvelope;
      try {
        decodedEnvelope = JSON.parse(item.content);
        console.log('Message content parsed successfully');
      } catch (err) {
        console.error('Error parsing message content:', err);
        await channel.nack(item, false, false); // Discard the message
        return;
      }

      let messages;
      try {
        messages = await Ably.Realtime.Message.fromEncodedArray(decodedEnvelope.messages || []);
        console.log('Ably messages decoded successfully');
      } catch (err) {
        console.error('Error decoding Ably messages:', err);
        await channel.nack(item, false, false); // Discard the message
        return;
      }

      console.log('Processing messages...');
      for (let message of messages) {
        console.log('Processing message:', message.data);
        var image_request = message.data;
        console.log('Received image request:', image_request);

        let data = JSON.stringify({
          "data": [
            image_request.prompt,
            image_request.width || 1920,
            image_request.height || 1080,
            12,
            2,
            -1,
            null,
            0,
            true
          ]
        });

        let config = {
          method: 'post',
          maxBodyLength: Infinity,
          url: 'http://localhost:7860/gradio_api/call/generate_image',
          headers: {
            'Content-Type': 'application/json'
          },
          data: data
        };

        try {
          console.log('Sending job generation request...');
          const response = await axios.request(config);
          console.log('Initial image generation request successful:', JSON.stringify(response.data));
          const result = response.data;
          var is_error = false;

          try {
            console.log('Sending image meta request...');
            const secondResponse = await axios.get("http://localhost:7860/gradio_api/call/generate_image/" + result.event_id.trim());
            console.log('Second generate image request successful');

            try {
              const responseData = secondResponse.data;
              const urlMatch = responseData.match(/"url":\s*"([^"]+)"/);
              const parsedUrl = urlMatch ? urlMatch[1] : null;
              console.log('Parsed URL:', parsedUrl);

              try {
                console.log('Downloading image from parsed URL...');
                var image = await axios.get(parsedUrl.replace("gradio_a/", ""), { responseType: 'arraybuffer' });
                console.log('Image downloaded successfully');
              } catch (downloadError) {
                console.error('Error downloading image:', downloadError);
                is_error = true;
                return;
              }

              try {
                const uploadParams = {
                  method: 'PUT',
                  url: `https://magickai-image-storage.botable.workers.dev/PIXE3/${Date.now()}_magick_image.webp`,
                  headers: {
                    'Content-Type': 'image/webp',
                    'Authorization': 'Bearer L9ile3DdbQIK3CauWD4Ej1znrytinKzzrz481jyD'
                  },
                  data: image.data
                };
                console.log('Uploading image to Cloudflare bucket...');
                const uploadResponse = await axios(uploadParams);
                console.log('Cloudflare upload successful -', uploadResponse.status);
                const imageUrl = uploadResponse.data;
                console.log('Image URL:', imageUrl);

                if (image_request.sessionId === 'API') {
                  console.log('Posting message back to callback URL...');
                  try {
                    await axios.post(image_request.callback, { imageUrl: imageUrl });
                    console.log('Callback POST request successful');
                  } catch (callbackError) {
                    console.error('Error posting to callback URL:', callbackError);
                    is_error = true;
                  }
                } else {
                  // Send Ably message
                  const channel = ably.channels.get(image_request.sessionId);
                  console.log('Sending Ably message to user session...');
                  await channel.publish("imageGenerated", { text: `<img src="${imageUrl}" width=500 />` }, (err) => {
                    if (err) {
                      console.error('Error sending Ably message:', err);
                      is_error = true;
                    } else {
                      console.log('Ably message sent successfully');
                    }
                  });
                }

                //Postback into the user's session

              } catch (uploadError) {
                console.error('Error uploading image to Cloudflare:', uploadError);
                is_error = true;
              }

            } catch (error) {
              console.error('Error making callback POST request:', error);
              is_error = true;
            }
            if (!is_error) {
              console.log('Acknowledging message...');
              await channel.ack(item);
            }
          } catch (error) {
            is_error = true;
            console.error('Error making image meta request:', error);
          }
        } catch (error) {
          console.error('Error in job generation request:', error);
        }
      }
    });
  } catch (err) {
    console.error('Error in connectToQueue function:', err);
    setTimeout(connectToQueue, 5000); // Retry after 5 seconds
  }
}

async function closeConnection() {
  try {
    if (channel) {
      console.log('Closing channel...');
      await channel.close();
      console.log('Channel closed');
    }
    if (connection) {
      console.log('Closing connection...');
      await connection.close();
      console.log('Connection closed');
    }
  } catch (err) {
    console.error('Error closing connection or channel:', err);
  }
}

async function main() {
  console.log(figlet.textSync('Magick AI', {
    font: 'Standard',
    horizontalLayout: 'default',
    verticalLayout: 'default'
  }));
  console.log('Magick Render Server');
  try {
    await connectToQueue();
    process.on('SIGINT', closeConnection);
    process.on('SIGTERM', closeConnection);
  } catch (err) {
    console.error('Error in main function:', err);
    setTimeout(main, 5000); // Retry main function after 5 seconds
  }
}

main();