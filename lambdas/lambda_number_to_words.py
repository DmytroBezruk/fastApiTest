def number_to_words(n):
    if n == 0:
        return "zero"
    if n < 0:
        return "minus " + number_to_words(-n)

    units = ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    teens = ["ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
             "sixteen", "seventeen", "eighteen", "nineteen"]
    tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
    thousands = ["", "thousand", "million", "billion", "trillion"]

    def chunk_to_words(num):
        words = []
        if num >= 100:
            words.append(units[num // 100] + " hundred")
            num %= 100
        if num >= 20:
            words.append(tens[num // 10])
            num %= 10
        elif num >= 10:
            words.append(teens[num - 10])
            num = 0
        if num > 0:
            words.append(units[num])
        return " ".join(words).strip()

    result = []
    chunk_count = 0
    while n > 0:
        n, chunk = divmod(n, 1000)
        if chunk > 0:
            result.append(f"{chunk_to_words(chunk)} {thousands[chunk_count]}".strip())
        chunk_count += 1

    return " ".join(reversed(result)).strip()


def lambda_handler(event, context):
    """Convert a single number (Map item) to its word form manually, including millions."""
    try:
        if isinstance(event, str):
            import json
            event = json.loads(event)
        if isinstance(event, dict) and "value" in event:
            value = event["value"]
        else:
            value = event
        value_int = int(value)
        return number_to_words(value_int)
    except Exception as e:
        return {"statusCode": 400, "error": str(e)}
