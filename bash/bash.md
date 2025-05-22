### Question 1
Write a Bash shell script that checks if a user exists in your system. If the user doesn't exist, the script should prompt the user to create the user with a strong password. The script should also ensure that the user's home directory is created.

### Example Solution 1
```
#!/bin/bash

if id "$1" >/dev/null 2>&1; then
    echo "User $1 exists! no further operation needed."
else
    echo "User $1 not found on system! Creating..."
    sudo useradd -m $1
    sudo passwd $1
fi
```

### Example Solution 2 (With Input Validation)
```
#!/bin/bash

# Function to validate username
validate_username() {
    local username=$1
    # Username must be 3-32 characters, start with a letter, and contain only letters, numbers, and underscores
    if [[ $username =~ ^[a-zA-Z][a-zA-Z0-9_]{2,31}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate password
validate_password() {
    local password=$1
    # Password must be at least 8 characters and contain at least one uppercase letter, one lowercase letter, and one number
    if [[ ${#password} -ge 8 && $password =~ [A-Z] && $password =~ [a-z] && $password =~ [0-9] ]]; then
        return 0
    else
        return 1
    fi
}

# Get username with validation
while true; do
    read -p "Enter username (3-32 chars, start with letter, only letters/numbers/underscores): " username
    if validate_username "$username"; then
        break
    else
        echo "Invalid username. Please try again."
    fi
done

# Check if user exists
if id "$username" >/dev/null 2>&1; then
    echo "User $username already exists!"
    exit 1
fi

# Get password with validation
while true; do
    read -s -p "Enter password (min 8 chars, at least one uppercase, one lowercase, one number): " password
    echo
    if validate_password "$password"; then
        read -s -p "Confirm password: " password_confirm
        echo
        if [ "$password" = "$password_confirm" ]; then
            break
        else
            echo "Passwords do not match. Please try again."
        fi
    else
        echo "Invalid password. Please try again."
    fi
done

# Create user with home directory
echo "Creating user $username..."
sudo useradd -m "$username"
echo "$username:$password" | sudo chpasswd
echo "User $username created successfully!"
```

