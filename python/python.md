# Palindrome Check

## Problem Description
For a given string S, write a function to check if it is a palindrome. Taking a single string as its parameter, your function should return `True` if the given string is a palindrome, else return `False`. A string is said to be a palindrome if it is the same when read backward.

## Example Solution
```python
def is_palindrome(s: str) -> bool:
    # Convert string to lowercase and remove non-alphanumeric characters
    cleaned_s = ''.join(c.lower() for c in s if c.isalnum())
    # Compare the string with its reverse
    return cleaned_s == cleaned_s[::-1]

# Example usage
test_cases = [
    "A man, a plan, a canal: Panama",  # True
    "race a car",                      # False
    "Was it a car or a cat I saw?",    # True
    "hello",                          # False
    "Madam, I'm Adam",                # True
]

# Test the function
for test in test_cases:
    result = is_palindrome(test)
    print(f"Input: '{test}'")
    print(f"Is palindrome: {result}\n")
```

## Explanation
The solution:
1. Takes a string input and returns a boolean
2. Cleans the input string by:
   - Converting to lowercase
   - Removing non-alphanumeric characters
3. Compares the cleaned string with its reverse using string slicing (`[::-1]`)
4. Returns `True` if they match, `False` otherwise

The solution handles:
- Case sensitivity (e.g., "Madam" is a palindrome)
- Spaces and punctuation (e.g., "A man, a plan, a canal: Panama" is a palindrome)
- Special characters and spaces

Time Complexity: O(n) where n is the length of the string
Space Complexity: O(n) for storing the cleaned string

# Login System Example

## Problem Description
Create a login system that continuously prompts the user for a username and password until valid credentials are entered.

## Example Solution
```python
def validate_login():
    # Sample user database (in real applications, use secure storage)
    valid_users = {
        "admin": "admin123",
        "user1": "pass123",
        "john_doe": "secure456"
    }
    
    while True:
        username = input("Enter username (or 'quit' to exit): ").strip()
        
        if username.lower() == 'quit':
            print("Exiting login system...")
            return False
            
        if username not in valid_users:
            print("Invalid username. Please try again.")
            continue
            
        password = input("Enter password: ").strip()
        
        if valid_users[username] == password:
            print(f"Welcome, {username}!")
            return True
        else:
            print("Invalid password. Please try again.")

# Example usage
if __name__ == "__main__":
    print("Welcome to the Login System")
    print("==========================")
    
    login_successful = validate_login()
    
    if login_successful:
        print("You are now logged in!")
    else:
        print("Login process terminated.")
```

## Explanation
The solution:
1. Defines a dictionary of valid username-password pairs
2. Uses a while loop to continuously prompt for credentials
3. Provides an exit option by typing 'quit'
4. Validates username first, then password
5. Returns True on successful login, False if user quits

Features:
- Input validation for both username and password
- Graceful exit option
- Clear error messages
- Separate username and password validation steps
- Case-sensitive matching for security

Note: In a real application, you would:
- Use secure password hashing (e.g., bcrypt)
- Store credentials in a secure database
- Implement rate limiting
- Add logging for security events
- Use HTTPS for credential transmission
