*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.RobotLogListener
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs

*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output
${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${username}=    Greet the user
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        Sleep    3s
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Close the browser
    Create a ZIP file of the receipts
    Success    USERNAME=${username}

*** Keywords ***
Greet the user
    Add heading    I am your Order Robot
    Add text input    myname    label=Please state your name here:    placeholder=Enter your name
    ${result}=    Run dialog
    [Return]    ${result.myname}

Open the robot order website
    Open Available Browser    ${url}

Get orders
    Download    ${csv_url}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}

Close the annoying modal
    Wait Until Page Contains Element    class:modal-content
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${myrow}
    Set Local Variable    ${order_no}    ${myrow}[Order number]
    Set Local Variable    ${head}    ${myrow}[Head]
    Set Local Variable    ${body}    ${myrow}[Body]
    Set Local Variable    ${legs}    ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]
    #
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    #
    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}
    #
    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}
    #
    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}
    #
    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element is Enabled    ${img_preview}

Submit the order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]
    #
    Mute Run On Failure    Page Should Contain Element
    #
    Click button    ${btn_order}
    Sleep    5s
    Page should contain element    ${lbl_receipt}

Take a screenshot of the robot
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]
    #
    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}
    #
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    #
    Set Local Variable    ${img_filename}    ${img_folder}${/}${orderid}.png
    #
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${img_filename}
    Capture Element Screenshot    ${img_robot}    ${img_filename}
    [Return]    ${orderid}    ${img_filename}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    #
    Wait Until Element Is Visible    //*[@id="receipt"]
    #
    Log To Console    Printing order ${ORDER_NUMBER}
    #
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    #
    Set Local Variable    ${pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    #
    Html To Pdf    content=${order_receipt_html}    output_path=${pdf_filename}
    #
    [Return]    ${pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    #
    Open Pdf    ${PDF_FILE}
    #
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    #
    Add Files To Pdf    ${myfiles}    ${PDF_FILE}    ${True}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Log out and close the browser
    Close Browser

Create a Zip file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Close the browser
    Close Browser

Success
    [Arguments]    ${USERNAME}
    Add icon    Success
    Add text    Dear ${USERNAME}, your orders have been placed.
    Run dialog    title=Success
