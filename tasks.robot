*** Settings ***
Documentation     A movie review sentiment analyzer robot. Tries to classify
...               written free-text reviews either as positive or negative.
...               How hard can it be? What could possibly go wrong? 😅
Library           RPA.core.notebook
Library           RPA.Browser.Selenium
Library           RPA.Cloud.AWS    robocloud_vault_name=aws

*** Variables ***
${AWS_REGION}=    us-east-2
${MOVIE_BROWSER_INDEX}=    2
${MOVIE_REVIEWS_WEBSITE_URL}=    http://www.rpachallenge.com
${SENTIMENT_ANALYSIS_WEBSITE_URL}=    https://www.danielsoper.com/sentimentanalysis/default.aspx
${SENTIMENT_BROWSER_INDEX}=    1
${USE_COMPREHEND}=    False

*** Keywords ***
Open movie reviews website
    Open Available Browser    ${MOVIE_REVIEWS_WEBSITE_URL}
    Maximize Browser Window
    Click Element When Visible    css:a[href="/movieSearch"]

*** Keywords ***
Initialize sentiment services
    IF    ${USE_COMPREHEND}
        Initialize Comprehend client
    ELSE
        Open sentiment analysis website
    END
    Open movie reviews website

*** Keywords ***
Open sentiment analysis website
    Open Available Browser    ${SENTIMENT_ANALYSIS_WEBSITE_URL}

*** Keywords ***
Initialize Comprehend client
    Init Comprehend Client
    ...    use_robocloud_vault=True
    ...    region=${AWS_REGION}

*** Keywords ***
Switch to movie reviews website
    IF    ${USE_COMPREHEND} == False
        Switch Browser    ${MOVIE_BROWSER_INDEX}
        Wait Until Page Contains    RPA Challenge
    END

*** Keywords ***
Search popular movies
    Switch to movie reviews website
    Click Button    Get Popular Movies
    ${movie_links_locator}=    Set Variable    css:span.linkPointer
    Wait Until Element Is Visible    ${movie_links_locator}

*** Keywords ***
Start challenge. This will be easy!
    Wait Until Page Does Not Contain Element    css:button.disabled
    Click Button    Start Timer

*** Keywords ***
Get movie links
    Switch to movie reviews website
    ${movie_links_locator}=    Set Variable    css:span.linkPointer
    Wait Until Element Is Visible    ${movie_links_locator}
    @{movie_links}=    Get WebElements    ${movie_links_locator}
    [Return]    @{movie_links}

*** Keywords ***
Get reviews
    ${reviews_locator}=    Set Variable    css:.reviewsText .card
    Wait Until Element Is Visible    ${reviews_locator}
    @{reviews}=    Get WebElements    ${reviews_locator}
    [Return]    @{reviews}

*** Keywords ***
Classify reviews as positive or negative. Not even breaking a sweat...
    @{movie_links}=    Get movie links
    FOR    ${movie_link}    IN    @{movie_links}
        Open movie modal    ${movie_link}
        @{reviews}=    Get reviews
        Classify reviews    @{reviews}
        Close movie modal
    END

*** Keywords ***
Open movie modal
    [Arguments]    ${movie_link}
    Click Element When Visible    ${movie_link}

*** Keywords ***
Comprehend sentiment
    [Arguments]    ${text}
    ${sentiment}=    Detect Sentiment    ${text}
    Notebook Json    ${sentiment}
    IF    "${sentiment["Sentiment"]}" == "NEGATIVE"
        ${sentiment_score}=    Set Variable    -1
    ELSE
        ${sentiment_score}=    Set Variable    1
    END
    [Return]    ${sentiment_score}

*** Keywords ***
Classify reviews
    [Arguments]    @{reviews}
    FOR    ${review}    IN    @{reviews}
        ${review_text}=
        ...    Get Text
        ...    ${review.find_element_by_class_name("card-content")}
        Notebook Print    REVIEW: ${review_text}
        IF    ${USE_COMPREHEND}
            ${sentiment}=    Comprehend sentiment    ${review_text}
        ELSE
            ${sentiment}=    Get sentiment    ${review_text}
        END
        Switch to movie reviews website
        ${actions}=
        ...    Get WebElement
        ...    ${review.find_element_by_class_name("card-action")}
        ${positive_link}=
        ...    Get WebElement
        ...    ${actions.find_element_by_css_selector("a:first-child")}
        ${negative_link}=
        ...    Get WebElement
        ...    ${actions.find_element_by_css_selector("a:last-child")}
        IF    ${sentiment} >= 0
            Click Link    ${positive_link}
        ELSE IF    ${sentiment} < 0
            Click Link    ${negative_link}
        END
    END

*** Keywords ***
Switch to sentiment analysis website
    IF    ${USE_COMPREHEND} == False
        Switch Browser    ${SENTIMENT_BROWSER_INDEX}
        Wait Until Page Contains    Free Sentiment Analyzer
    END

*** Keywords ***
Get sentiment
    [Arguments]    ${text}
    Switch to sentiment analysis website
    Input Text    accordionPaneSentimentAnalysis_content_txtText    ${text}
    Click Button    accordionPaneSentimentAnalysis_content_btnAnalyzeText
    Wait Until Element Is Visible
    ...    css:#accordionPaneSentimentAnalysis_content_lblInterpretation span:nth-of-type(2)
    ${sentiment_score_text}=
    ...    Get Text
    ...    css:#accordionPaneSentimentAnalysis_content_lblInterpretation span:nth-of-type(2)
    ${sentiment_score}=    Convert To Number    ${sentiment_score_text}
    Notebook Print    SENTIMENT: ${sentiment_score}
    [Return]    ${sentiment_score}

*** Keywords ***
Close movie modal
    Switch to movie reviews website
    Click Element When Visible    css:.modal-close
    Wait Until Page Does Not Contain Element
    ...    css:.modal-overlay.velocity-animating

*** Keywords ***
Submit challenge. See? Easy!
    Click Button    Submit

*** Keywords ***
Admire my accomplishment!
    Wait Until Element Is Visible    css=.congratulations
    Capture Element Screenshot
    ...    css=.congratulations
    ...    challenge-results.png

*** Tasks ***
Analyze movie reviews, like a boss.
    Initialize sentiment services
    Search popular movies
    Start challenge. This will be easy!
    Classify reviews as positive or negative. Not even breaking a sweat...
    Submit challenge. See? Easy!
    Admire my accomplishment!
    [Teardown]    Close All Browsers
