"""
Utility functions for the recommendation app.
"""
import json


def build_gpt_analysis_prompt(card_data, analysis_category, store_name=None, store_address=None):
    """
    Build the GPT prompt for credit card analysis.

    Args:
        card_data: List of card dictionaries with reward information
        analysis_category: The spending category to analyze (e.g., "dining")
        store_name: Optional name of the store/merchant
        store_address: Optional address of the store/merchant

    Returns:
        str: The formatted prompt for GPT
    """
    # Build store information string if provided
    store_info = ""
    if store_name or store_address:
        store_info = "\n\nSTORE INFORMATION:\n"
        if store_name:
            store_info += f"Store Name: {store_name}\n"
        if store_address:
            store_info += f"Store Address: {store_address}\n"
        store_info += "\nUse this store information to provide more specific and contextual recommendations."

    prompt = f"""
        You are a credit card expert with extensive knowledge of credit card rewards programs. Analyze the following credit cards for spending in the "{analysis_category}" category and rank them from best to worst with detailed explanations.
        {store_info}

        CRITICAL: Use the most accurate and up-to-date benefit and rewards information available. Prioritize current card terms, recent reward structure updates, and the latest known reward rates when making your analysis.

        Cards to analyze:
        {json.dumps(card_data, indent=2)}

        CRITICAL INSTRUCTIONS FOR ESTIMATING REWARDS:
        - If a specific reward category is missing from the database, you MUST use your knowledge of the card to estimate the rewards
        - IMPORTANT: Check if the card has an "other" category reward - this typically represents the base/default reward rate for all purchases
        - If an "other" category exists with rewards, use that as the baseline for {analysis_category} unless you know the card has a different rate for this category
        - Look at other reward categories provided for the card to understand the card's general reward structure
        - Use your knowledge of the card name and issuer to infer typical rewards
        - If the card has rewards in other categories, use that as a baseline to estimate rewards for {analysis_category}
        - For cards with no specific category bonus, estimate based on the card's base rewards rate
        - NEVER return "unavailable" or 0.0 unless you are absolutely certain the card offers NO rewards at all
        - Always provide your best estimate based on card knowledge, even if database data is incomplete

        For each card, provide:
        1. The specific benefits for {analysis_category} spending (use your knowledge if database data is missing)
        2. A clear explanation of why this card is good/bad for {analysis_category}
        3. Any limitations or restrictions
        4. The estimated value/return for {analysis_category} spending
        5. Calculate the "value" field as a DECIMAL PERCENTAGE (what percentage of spending you save):
           - FIRST: Check if rewards exist in the database for this category - use those if available
           - If database data is missing: Use your knowledge of the card to estimate
           - For cashback: use the cashback_percentage directly (e.g., 0.25 = 2.5% savings)
           - For points: estimate based on typical point values (1 point usually = 0.01 or 1% value, adjust based on card)
           - The value should always represent the percentage of spending saved (e.g., 0.25 means you save 2.5% of your spending)
           - Provide your best estimate - avoid 0.0 unless truly no rewards exist
        6. Set "reward_type" to "cashback" if cashback is available, otherwise "points" (use your knowledge to determine)
        7. Set "reward_amount" to a NUMBER (not a string): estimate the cashback_percentage or points multiplier based on your knowledge of the card, or null only if absolutely no rewards exist
        8. Set "category" to the matched category name

        Return your response as a JSON object with this structure:
        {{
            "analysis": [
                {{
                    "card_id": 123,
                    "card_name": "Card Name",
                    "issuer": "Card Issuer",
                    "value": 0.25,  // Always a decimal percentage (e.g., 0.25 = 2.5% of spending saved) - MUST be a number
                    "reward_type": "cashback",
                    "reward_amount": 2.5,  // MUST be a number (not a string), or null if unavailable
                    "category": "dining",
                    "benefits": ["Benefit 1", "Benefit 2"],
                    "explanation": "Detailed explanation of why this card is good for this category",
                    "limitations": ["Any limitations or restrictions"],
                    "estimated_value": "2.5% cashback or 2.5x points"
                }}
            ]
        }}

        IMPORTANT:
        - Return the cards in order from BEST to WORST for {analysis_category} spending. The first card in the array should be the best option, and the last should be the worst option.
        - Return ONLY the JSON object, no additional text or explanations outside the JSON.
        - ALWAYS estimate rewards using your card knowledge - never return 0.0 or "unavailable" unless the card truly offers no rewards
        """

    return prompt


def build_gpt_streaming_analysis_prompt(card_data, analysis_category, store_name=None, store_address=None):
    """
    Build the GPT prompt for streaming credit card analysis.
    This version instructs GPT to return ranking first, then full analysis.

    Args:
        card_data: List of card dictionaries with reward information
        analysis_category: The spending category to analyze (e.g., "dining")
        store_name: Optional name of the store/merchant
        store_address: Optional address of the store/merchant

    Returns:
        str: The formatted prompt for GPT
    """
    # Build store information string if provided
    store_info = ""
    if store_name or store_address:
        store_info = "\n\nSTORE INFORMATION:\n"
        if store_name:
            store_info += f"Store Name: {store_name}\n"
        if store_address:
            store_address += f"Store Address: {store_address}\n"
        store_info += "\nUse this store information to provide more specific and contextual recommendations."

    prompt = f"""
        You are a credit card expert with extensive knowledge of credit card rewards programs. Analyze the following credit cards for spending in the "{analysis_category}" category and rank them from best to worst with detailed explanations.
        {store_info}

        CRITICAL: Use the most accurate and up-to-date benefit and rewards information available. Prioritize current card terms, recent reward structure updates, and the latest known reward rates when making your analysis.

        Cards to analyze:
        {json.dumps(card_data, indent=2)}

        CRITICAL INSTRUCTIONS FOR ESTIMATING REWARDS:
        - If a specific reward category is missing from the database, you MUST use your knowledge of the card to estimate the rewards
        - IMPORTANT: Check if the card has an "other" category reward - this typically represents the base/default reward rate for all purchases
        - If an "other" category exists with rewards, use that as the baseline for {analysis_category} unless you know the card has a different rate for this category
        - Look at other reward categories provided for the card to understand the card's general reward structure
        - Use your knowledge of the card name and issuer to infer typical rewards
        - If the card has rewards in other categories, use that as a baseline to estimate rewards for {analysis_category}
        - For cards with no specific category bonus, estimate based on the card's base rewards rate
        - NEVER return "unavailable" or 0.0 unless you are absolutely certain the card offers NO rewards at all
        - Always provide your best estimate based on card knowledge, even if database data is incomplete

        For each card, provide:
        1. The specific benefits for {analysis_category} spending (use your knowledge if database data is missing)
        2. A clear explanation of why this card is good/bad for {analysis_category}
        3. Any limitations or restrictions
        4. The estimated value/return for {analysis_category} spending
        5. Calculate the "value" field as a DECIMAL PERCENTAGE (what percentage of spending you save):
           - FIRST: Check if rewards exist in the database for this category - use those if available
           - If database data is missing: Use your knowledge of the card to estimate
           - For cashback: use the cashback_percentage directly (e.g., 0.25 = 2.5% savings)
           - For points: estimate based on typical point values (1 point usually = 0.01 or 1% value, adjust based on card)
           - The value should always represent the percentage of spending saved (e.g., 0.25 means you save 2.5% of your spending)
           - Provide your best estimate - avoid 0.0 unless truly no rewards exist
        6. Set "reward_type" to "cashback" if cashback is available, otherwise "points" (use your knowledge to determine)
        7. Set "reward_amount" to a NUMBER (not a string): estimate the cashback_percentage or points multiplier based on your knowledge of the card, or null only if absolutely no rewards exist
        8. Set "category" to the matched category name

        Return your response as a JSON object with this EXACT structure in TWO parts:

        PART 1 - RANKING (return this first):
        {{
            "ranking": [
                {{
                    "card_id": "123",
                    "card_name": "Card Name",
                    "issuer": "Card Issuer",
                    "value": 0.25,
                    "reward_type": "cashback",
                    "reward_amount": 2.5,
                    "category": "dining"
                }},
                {{
                    "card_id": "456",
                    "card_name": "Another Card",
                    "issuer": "Another Issuer",
                    "value": 0.20,
                    "reward_type": "points",
                    "reward_amount": 2.0,
                    "category": "dining"
                }}
            ],

        PART 2 - FULL ANALYSIS (return this after ranking):
            "analysis": [
                {{
                    "card_id": 123,
                    "card_name": "Card Name",
                    "issuer": "Card Issuer",
                    "value": 0.25,
                    "reward_type": "cashback",
                    "reward_amount": 2.5,
                    "category": "dining",
                    "benefits": ["Benefit 1", "Benefit 2"],
                    "explanation": "Detailed explanation of why this card is good for this category",
                    "limitations": ["Any limitations or restrictions"],
                    "estimated_value": "2.5% cashback or 2.5x points"
                }}
            ]
        }}

        IMPORTANT:
        - Return the cards in order from BEST to WORST for {analysis_category} spending in BOTH ranking and analysis sections
        - The first card in both arrays should be the best option, and the last should be the worst option
        - Return ONLY the JSON object, no additional text or explanations outside the JSON
        - ALWAYS estimate rewards using your card knowledge - never return 0.0 or "unavailable" unless the card truly offers no rewards
        - Make sure the JSON is properly formatted with the ranking array first, followed by the analysis array
        """

    return prompt


def build_card_details_prompt(card_data):
    """
    Build the GPT prompt for analyzing a single card's details.

    Args:
        card_data: Dictionary with card information including rewards

    Returns:
        str: The formatted prompt for GPT
    """
    prompt = f"""
        You are a credit card expert with extensive knowledge of credit card rewards programs, benefits, and features. Analyze the following credit card and provide comprehensive information about it.

        CRITICAL: Use the most accurate and up-to-date information available. Prioritize current card terms, recent updates, and the latest known features and benefits.

        Card to analyze:
        {json.dumps(card_data, indent=2)}

        INSTRUCTIONS:
        - Use the database information provided as a baseline
        - Enhance with your knowledge of this specific card to provide complete, accurate information
        - Include ALL benefits, features, and rewards this card offers
        - If the database has an "other" category, that represents the base/default reward rate for all purchases
        - Provide accurate annual fee, welcome bonus, and other key features
        - Be specific about reward categories and their rates
        - Mention any limitations, caps, or restrictions
        - Include information about additional benefits (travel insurance, purchase protection, airport lounge access, etc.)

        Return your response as a JSON object with this structure:
        {{
            "card_id": "123",
            "card_name": "Card Name",
            "issuer": "Card Issuer",
            "rewards_summary": "3% on dining, 2% on travel, 1% on everything else",
            "key_benefits": [
                "No foreign transaction fees",
                "Travel insurance",
                "Purchase protection"
            ],
            "reward_categories": [
                {{
                    "category": "dining",
                    "reward_type": "points",
                    "reward_amount": 3,
                    "value": 0.03,
                    "limit": null,
                    "reset_period": null,
                    "description": "3x points on dining at restaurants"
                }},
                {{
                    "category": "travel",
                    "reward_type": "points",
                    "reward_amount": 2,
                    "value": 0.02,
                    "limit": null,
                    "reset_period": null,
                    "description": "2x points on travel purchases"
                }}
            ],
            "additional_benefits": [
                "Airport lounge access",
                "Travel insurance coverage",
                "Purchase protection up to $500"
            ],
            "network": "Visa/Mastercard/Amex/Discover"
        }}

        IMPORTANT:
        - Ensure all reward amounts and values are accurate numbers
        - The "value" field should be a decimal (e.g., 0.03 = 3%)
        - Return ONLY the JSON object, no additional text
        - Use your knowledge to fill in any missing information from the database
        - Be comprehensive but concise
        """

    return prompt
