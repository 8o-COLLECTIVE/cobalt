import setuptools

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name="cobalt8", # Replace with your own username
    version="0.0.1",
    author="8o COLLECTIVE",
    author_email="8ocollective@birdlover.com",
    description="Offline AES encryption with a Discord context in mind.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/8o-COLLECTIVE/cobalt8",
    install_requires=[
        'pyperclip',
        'discord',
        'gitpython'
    ],
    entry_points={
              'console_scripts': [
                  'cobalt8 = cobalt8.cobalt8:entry',
              ],
          },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    packages=['cobalt8'],
    python_requires=">=3.3",
)
