# from collections import Counter
import os
from pathlib import Path
# from random import choice
from random import seed
from typing import List, Union

# import requests
# from requests.exceptions import ConnectionError
# from gensim.utils import simple_preprocess


S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"

def task_1():
    seed(1)
    try:
        with open(PATH_TO_NAMES, 'r') as names_file, open(PATH_TO_SURNAMES, 'r') as last_names_file:
            names = sorted(name.strip().lower() for name in names_file)
            last_names = [surname.strip().lower() for surname in last_names_file]

            with open(PATH_TO_OUTPUT, 'w') as output_file:
                for name in names:
                    surname = choice(last_names)
                    output_file.write(f"{name} {surname}\n")
    except Exception as e:
        print(f"An error occurred: {e}")

def task_2(top_k: int):
    try:
        with open(PATH_TO_TEXT, 'r') as text_file, open(PATH_TO_STOP_WORDS, 'r') as stop_words_file:
            text = text_file.read().lower()
            stop_words = set(stop_words_file.read().splitlines())

            words = re.findall(r'[a-z]+', text)
            filtered_words = [word for word in words if word not in stop_words]

            word_counts = Counter(filtered_words)
            return word_counts.most_common(top_k)
    except Exception as e:
        print(f"An error occurred: {e}")

def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except RequestException as e:
        raise RequestException(f"An error occurred: {e}")

def task_4(data: List[Union[int, str, float]]):
    total = 0
    try:
        for item in data:
            try:
                total += float(item)
            except ValueError:
                raise TypeError(f"Unable to convert {item} to float.")
        return total
    except TypeError as e:
        print(f"An error occurred: {e}")

def task_5():
    try:
        a, b = input("Enter two numbers separated by space: ").split()
        a = float(a)
        b = float(b)

        if b == 0:
            print("Can't divide by zero")
        else:
            print(a / b)
    except ValueError:
        print("Entered value is wrong")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
