//
//  ClipboardSamples.swift
//  IridiumTests
//

enum ClipboardSamples {
    static let swiftCode = """
    import SwiftUI

    @Observable
    final class ViewModel {
        var items: [String] = []

        func load() async {
            let data = try? await URLSession.shared.data(from: url)
        }
    }
    """

    static let pythonCode = """
    import pandas as pd
    from sklearn.model_selection import train_test_split

    def train_model(data):
        X_train, X_test, y_train, y_test = train_test_split(
            data.features, data.labels, test_size=0.2
        )
        return model.fit(X_train, y_train)
    """

    static let javascriptCode = """
    const express = require('express');
    const app = express();

    app.get('/api/users', async (req, res) => {
        const users = await db.query('SELECT * FROM users');
        res.json(users);
    });

    console.log('Server started');
    """

    static let typescriptCode = """
    interface User {
        id: number;
        name: string;
        email: string;
        isActive: boolean;
    }

    export const getUser = async (id: number): Promise<User> => {
        const response = await fetch(`/api/users/${id}`);
        return response.json();
    };
    """

    static let htmlCode = """
    <html>
    <body>
        <div class="container">
            <h1>Hello World</h1>
            <span id="content">Welcome</span>
        </div>
    </body>
    </html>
    """

    static let url = "https://github.com/cicm/Iridium/pull/1"
    static let email = "user@example.com"

    static let prose = """
    The quick brown fox jumps over the lazy dog. This is a sample paragraph
    that contains natural language text, not code. It should be classified
    as prose by the pattern matcher and NL classifier.
    """

    static let shellScript = """
    #!/bin/bash
    echo "Deploying to production..."
    export NODE_ENV=production
    if [ -f .env ]; then
        source .env
    fi
    """

    static let sqlQuery = """
    SELECT users.name, orders.total
    FROM users
    INNER JOIN orders ON users.id = orders.user_id
    WHERE orders.total > 100
    """

    static let rustCode = """
    pub fn fibonacci(n: u64) -> u64 {
        let mut a: u64 = 0;
        let mut b: u64 = 1;
        for _ in 0..n {
            let temp = b;
            b = a + b;
            a = temp;
        }
        a
    }
    """

    static let goCode = """
    package main

    import "fmt"

    func main() {
        result := fibonacci(10)
        fmt.Println(result)
    }
    """
}
