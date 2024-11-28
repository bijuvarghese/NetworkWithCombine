# NetworkWithCombine

NetworkWithCombine is a Swift project that demonstrates how to use the Combine framework for networking tasks.

## Features

- Utilizes the Combine framework for handling asynchronous events.
- Provides examples of making network requests using Combine.
- Demonstrates error handling and data parsing with Combine.

## Requirements

- iOS 13.0+ / macOS 10.15+
- Xcode 11+
- Swift 5.1+

## Installation

Clone the repository:

```sh
git clone https://github.com/bijuvarghese/NetworkWithCombine.git
```sh

Open the project in Xcode:

cd NetworkWithCombine
open NetworkWithCombine.xcodeproj
## Usage
Import the necessary modules:
import Combine
import Foundation
Create a network request using Combine:
let url = URL(string: "https://api.example.com/data")!
let publisher = URLSession.shared.dataTaskPublisher(for: url)
    .map { $0.data }
    .decode(type: MyDataType.self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
Subscribe to the publisher:
let cancellable = publisher.sink(
    receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("Finished successfully")
        case .failure(let error):
            print("Failed with error: \(error)")
        }
    },
    receiveValue: { data in
        print("Received data: \(data)")
    }
)
Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

License
This project is licensed under the MIT License.

