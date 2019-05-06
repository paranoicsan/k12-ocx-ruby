```sh
gem instal bundler
bundle install
```

## Working with JSON-LD structured data

Inside `json-ld` directory run the first script to generate framed document
```sh
cd json-ld
./build-frame.rb
```
That will produce [framed document](json-ld/result.json?raw=true)

Execute sample script to generate new document with brand new markup
```sh
cd json-ld
./build-new-document.rb
```
That will build new HTML [document](data/json-ld-updated.html?raw=true)

## Working with RDFa structured data

Inside `rfda` directory run the first script to generate the graph to be used as reference
```sh
cd rdfa
./build-graph.rb
```
That will produce [graph](rdfa/graph-rdfa.html?raw=true)

Execute sample script to generate new document with brand new markup
```sh
cd rdfa
./build-new-document.rb
```
That will build new HTML [document](data/rdfa-updated.html?raw=true)
