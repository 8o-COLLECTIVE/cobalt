import discord
import hashlib
import aes

# Create an anonymous discord client, which retrieves the content of the selected channel and then dies.

print("Establishing Discord client, please hold...")

client = discord.Client()

@client.event
async def on_ready():
    to_scrape = input("\nInput channel ID to be scraped [or press enter for #cobalt]: ")
    print()
    if len(to_scrape) == 0:
        to_scrape = 813872961656193045

    try:
        channel = client.get_channel(int(to_scrape))
    except:
        print("It would appear that key is invalid.")
        pass

    key = input("Conversation key: ")

    aesobj = aes.AES(bytearray.fromhex(key))

    key_hash = hashlib.md5(bytearray.fromhex(key)).hexdigest()

    print("\nLoading conversation...\n")

    if channel is not None:

        messages = await channel.history().flatten()
        stack = []
        for item in messages:
            if item.content.startswith(key_hash):
                text = item.content
                text = text[32:]

                iv = text[:32]
                text = text[32:]

                stack.append("[" + str(item.created_at) + "] " + item.author.name + f": {aesobj.decrypt_ctr(bytearray.fromhex(text), bytearray.fromhex(iv)).decode('ascii')}")

        for x in range(len(stack)):
            print(stack.pop())

    else:
        print("\nFailed to find channel with provided ID")
        toScrape = input("\nDo you want to try again? [Y or N] ")
        if(toScrape.lower() == "y"):
            await on_ready()
    await client.close()

client.run('ODAxMjE4ODI4MDA0MjI5MTIw.YAdfLg.B9dRxE5X7UmyhCmhf_-vEz4pRCY')
