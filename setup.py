import setuptools
import os

about = {}
with open(os.path.join(os.path.dirname(__file__), "cobalt8", "__version__.py")) as f:
    exec(f.read(), about)

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setuptools.setup(
    name=about["__title__"],
    packages=["cobalt8"],
    version=about["__version__"],
    description=about["__description__"],
    long_description=long_description,
    long_description_content_type="text/markdown",
    license=about["__license__"],
    author=about["__author__"],
    author_email=about["__author_email__"],
    url=about["__url__"],
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
    python_requires=">=3.3",
)
