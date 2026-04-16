#!/bin/bash
set -e

echo "Compiling tests..."
g++ -I sensors/include -I tests/mock_headers -std=c++17 tests/test_SensorNotifier.cpp sensors/SensorNotifier.cpp -pthread -o tests/test_SensorNotifier

echo "Running tests..."
./tests/test_SensorNotifier

echo "Tests completed successfully."
