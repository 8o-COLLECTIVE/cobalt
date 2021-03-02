import discord
import hashlib

from .aes import AES

# Create an anonymous discord client, which retrieves the content of the selected channel and then dies.


def scrape():
    print("Establishing Discord client, please hold...")
    
    client = discord.Client()
    
    client.run('ODAxMjE4ODI4MDA0MjI5MTIw.YAdfLg._IxT1qxs3AaFFig-7e6GwC50c9s')
    
    @client.event
    async def on_ready():
        channel = get_channel

        key = input("\nConversation key: ")

        aesobj = AES(bytearray.fromhex(key))

        key_hash = hashlib.md5(bytearray.fromhex(key)).hexdigest()

        print("\nLoading conversation...\n")

        if channel is not None:
            multi_decrypt(key_hash)

        else:
            print("\nFailed to find channel with provided ID")
            toScrape = input("\nDo you want to try again? [Y or N] ")
            if(toScrape.lower() == "y"):
                await on_ready()
        await client.close()


def get_channel():
    to_scrape = input("\nInput channel ID to be scraped [or press enter for #cobalt]: ")
    if len(to_scrape) == 0:
        to_scrape = 813872961656193045

    try:
        channel = client.get_channel(int(to_scrape))
    except:
        print("\nIt would appear that key is invalid.")
        pass
        
    return channel
    
    
def decrypt_text(text):
    format_message = lambda datetime, author, dmessage: "[{}] {}: {}".format(datetime, author, dmessage)
    text = item.content
    text = text[32:]

    iv = text[:32]
    text = text[32:]
    
    dmessage = aesobj.decrypt_ctr(bytearray.fromhex(text), bytearray.fromhex(iv)).decode('ascii')
    
    messagef = format_message(str(item.created_at), item.author.name, dmessage)

    return messagef
    
    
async def multi_decrypt(key_hash):
    messages = await channel.history().flatten()
            
    stack = [decrypt_text(item.content) for item in messages if item.content.startswith(key_hash)]

    for x in range(len(stack)):
        print(stack.pop())
