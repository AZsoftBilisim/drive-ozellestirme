
#Region Internal

#Region EDIWithBanks

// Returns data from the statement file
//
// Parameters:
//    StatementLines - Array - Array of extract file lines
//    ReadDocuments - Boolean - Indicates that the entire statement, including documents, has been read.
//
// Returns:
//    Structure - Statement data
//
Function Parse1CClientBankExchangeStatementFile(StatementLines, ReadDocuments = True) Export
	

	If TypeOf(StatementLines) <> Type("Array") Then
		Return Undefined;
	EndIf;
	
	Result = New Structure("Title, AccountList, SettlementAccounts, StatementDocuments, ParsingErrors");
	StatementTitle        = Undefined;
	ListOfStatementAccounts     = New Array;
	CurrentAccountsStatements   = New Array;
	StatementDocuments        = New Array;
	ParsingErrors           = New Array;
	TitlesMap  = RelationOfStatementTagsToKeys();
	
	Try
	
	RowsCount = StatementLines.Count();
	CurrentRow = 1;
	While CurrentRow < RowsCount Do
		
		Page1 = GetImportString(CurrentRow, RowsCount, StatementLines);
		
		Value = "";
		Tag_ = "";
		ParseTagString(Page1, Tag_, Value);
		
		If Left(Upper(TrimAll(Page1)), 14) = "СЕКЦИЯДОКУМЕНТ" Then //@NON-NLS-1
			
			If Not ReadDocuments Then
				Break;
			EndIf;
			
			DocumentLineTags = DocumentLineTags();
			DocumentLineTags.Operation = Value;
			
			LoadSectionOfDocument(DocumentLineTags, CurrentRow, RowsCount, StatementLines, TitlesMap);
			
			StatementDocuments.Add(DocumentLineTags);
			
		ElsIf Left(Upper(TrimAll(Page1)), 14) = "СЕКЦИЯРАСЧСЧЕТ" Then //@NON-NLS-1
			
			RsAccountStructure = LoadInvoicePaymentSection(CurrentRow, RowsCount, StatementLines, TitlesMap);
			If RsAccountStructure <> Undefined Then
				CurrentAccountsStatements.Add(RsAccountStructure);
			EndIf;
			
		ElsIf Left(Upper(TrimAll(Page1)), 8) = "РАСЧСЧЕТ" Then //@NON-NLS-1
			
			Value = "";
			Tag_      = "";
			ParseTagString(Page1, Tag_, Value);
			If Tag_ = "РАСЧСЧЕТ" Then //@NON-NLS-1
				If ListOfStatementAccounts.Find(Value) = Undefined Then
					ListOfStatementAccounts.Add(Value);
				EndIf;
			EndIf;
			
		ElsIf Left(Upper(TrimAll(Page1)), 10) = "КОНЕЦФАЙЛА" Then //@NON-NLS-1
			Break;
			
		ElsIf Left(Upper(TrimAll(Page1)), 20) = "1CCLIENTBANKEXCHANGE" Then //@NON-NLS-1
			Continue;
			
		Else
			LoadTitleBar(Page1, CurrentRow, StatementTitle, TitlesMap);
			
		EndIf;
	EndDo;
	
	If ListOfStatementAccounts.Count() = 0 Then
		
		For Each LineByAccount In CurrentAccountsStatements Do
			
			If ListOfStatementAccounts.Find(LineByAccount.CreateAccount_1) = Undefined Then
				ListOfStatementAccounts.Add(LineByAccount.CreateAccount_1);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result.Title        = StatementTitle;
	Result.AccountList     = ListOfStatementAccounts;
	Result.SettlementAccounts   = CurrentAccountsStatements;
	Result.ParsingErrors    = ParsingErrors;
	Result.StatementDocuments = StatementDocuments;
	
	Except
		
		ParsingErrors.Add(NStr("vi = 'Cấu trúc tệp không tương ứng với định dạng được hỗ trợ.';
								|ru = 'Структура файла не соответствует поддерживаемому формату.';
								|en = 'The file structure does not match the supported format.'; fa = 'The file structure does not match the supported format.';
								|it = 'La struttura del file non corrisponde al formato supportato.';
								|pl = 'Struktura pliku nie jest zgodna z obsługiwanym formatem.';
								|tr = 'Dosya yapısı desteklenen formatla eşleşmiyor.'"));
		
		Result.Title        = StatementTitle;
		Result.AccountList     = ListOfStatementAccounts;
		Result.SettlementAccounts   = CurrentAccountsStatements;
		Result.ParsingErrors    = ParsingErrors;
		Result.StatementDocuments = StatementDocuments;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Converts a string to a date value. If it fails, returns an empty date.
//
// Parameters:
//    Source - String - Converted value.
//
// Returns:
//    Date - Received date
//
Function GetDateFromString(Val Source) Export
	
	Receiver = '00010101';
	
	If IsBlankString(Source) Then
		Return Receiver;
	EndIf;
	
	Try
		
		Receiver = Date(Source);
		
	Except
	
		Buffer = Source;
		
		PointPosition = StrFind(Buffer, ".");
		
		If PointPosition = 0 Then
			Return Receiver;
		EndIf;
		
		DateNumber_ = Left(Buffer, PointPosition - 1);
		Buffer = Mid(Buffer, PointPosition + 1);
		
		PointPosition = StrFind(Buffer, ".");
		
		If PointPosition = 0 Then
			Return Receiver;
		EndIf;
		
		DateMonth = Left(Buffer, PointPosition - 1);
		DateYear = Mid(Buffer, PointPosition + 1);
		
		Try
			
			If StrLen(DateYear) = 2 Then
			
				If Number(DateYear) < 50 Then
					DateYear = "20" + DateYear;
				Else
					DateYear = "19" + DateYear;
				EndIf;
			
			EndIf;
			
		Except
			Return Receiver;
		EndTry;
		
		Try
			
			Receiver = Date(Number(DateYear), Number(DateMonth), Number(DateNumber_));
			
		Except
			
			Return Receiver;
			
		EndTry;
	EndTry;
	
	Return Receiver;
	
EndFunction

// Converts a string to a numeric value. If it fails it returns Undefined.
//
// Parameters:
//    Buffer - String, Number - Converted value.
//
// Returns:
//    Number - The resulting number
//
Function ConvertToNumber(Val Buffer) Export
	
	If TypeOf(Buffer) = Type("Number") Then
		Return Buffer;
	EndIf;
	
	Buffer = TrimAll(StrReplace(Buffer, " ", ""));
	If Not IsBlankString(Buffer)
		And StringFunctionsClientServer.OnlyNumbersInString(StrReplace(StrReplace(StrReplace(Buffer, ".", ""), "-", ""), ",", "")) Then
		Result = Number(Buffer);
		If Result < 0 Then
			Result = - Result;
		EndIf;
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an empty structure to fill in when reading an extract from a file
// 
// Returns:
// 	Structure - LongDesc:
// * Number - String - 
// * Date - String -  
// * Sum - String - 
// * PaymentKind - String -
// * PaymentKind_ - String -
// * Operation - String -
// * ReceiptDate - String -
// * ReceiptTime - String -
// * ReceiptContent - String -
// * DepartureDate - String -
// * ArrivalDate_ - String -
// * PayerAccount - String -
// * Payer - String -
// * PayerTIN - String -
// * Payer1 - String -
// * PayerInternationalName - String - 
// * PayerCountry - String -
// * PayerBankAccount - String -
// * PayerBank_1 - String -
// * PayerBank_2 - String -
// * PayerBIC - String -
// * PayerCorAccount - String -
// * PayerBank_3 - String -
// * PayerBank_4 - String -
// * PayerBank_5 - String -
// * PayerSWIFT - String -
// * Payer2 - String -
// * Payer3 - String -
// * Payer4 - String -
// * BeneficiaryAccount - String -
// * Recipient - String -
// * BeneficiaryTIN - String -
// * Recipient1 - String -
// * RecipientInternationalName - String - 
// * RecipientCountry - String -
// * RecipientBankAccount - String -
// * RecipientBank_1 - String -
// * RecipientBank_2 - String -
// * BeneficiaryBIC - String -
// * BeneficiaryCorAccount - String -
// * RecipientBank_3 - String -
// * RecipientBank_4 - String -
// * RecipientBank_5 - String -
// * BeneficiarySWIFT - String -
// * Recipient2 - String -
// * Recipient3 - String -
// * Recipient4 - String -
// * AuthorStatus - String -
// * KPPPayer - String -
// * BeneficiaryCRTR - String -
// * IndicatorBCC - String -
// * RNCPS - String -
// * MUNICIPALTERRITORIESCLASSIFIER - String -
// * BasisIndicator - String - 
// * PeriodIndicator - String -
// * NumberIndicator - String -
// * DateIndicator - String -
// * TypeIndicator - String -
// * Code - String -
// * PaymentPurposeCode - String -
// * PaymentPurposes - String -
// * PaymentPurposes1 - String -
// * PaymentPurposes2 - String -
// * PaymentPurposes3 - String -
// * PaymentPurposes4 - String -
// * PaymentPurposes5 - String -
// * PaymentPurposes6 - String -
// * PaymentTerm - String -
// * RankingInPriority - String -
// * PaymentTerm1 - String -
// * PaymentTerm2 - String -
// * PaymentTerm3 - String -
// * AcceptanceTerm - String -
// * KindOfLetterOfCredit - String -
// * PaymentByView - String -
// * AdditionConditions - String -
// * PurchaseCommercialInvoiceNumber - String -
// * DateOfSendingDoc - String -
// * StatementData - String -
Function DocumentLineTags() Export
	
	Return New Structure(
		"Number, Date, Sum,
		|PaymentKind, PaymentKind_, Operation,
		|ReceiptDate, ReceiptTime, ReceiptContent,
		|DepartureDate, ArrivalDate_,
		|PayerAccount, Payer, PayerTIN, Payer1, PayerInternationalName, PayerCountry,
		|PayerBankAccount, PayerBank_1, PayerBank_2, PayerBIC, PayerCorAccount,
		|PayerBank_3, PayerBank_4, PayerBank_5, PayerSWIFT,
		|Payer2, Payer3, Payer4,
		|BeneficiaryAccount, Recipient, BeneficiaryTIN, Recipient1, RecipientInternationalName, RecipientCountry,
		|RecipientBankAccount, RecipientBank_1, RecipientBank_2, BeneficiaryBIC, BeneficiaryCorAccount,
		|RecipientBank_3, RecipientBank_4, RecipientBank_5, BeneficiarySWIFT,
		|Recipient2, Recipient3, Recipient4,
		|AuthorStatus, KPPPayer, BeneficiaryCRTR, IndicatorBCC, RNCPS, MUNICIPALTERRITORIESCLASSIFIER,
		|BasisIndicator, PeriodIndicator, NumberIndicator, DateIndicator, TypeIndicator,
		|Code,
		|PaymentPurposeCode,
		|PaymentPurposes, PaymentPurposes1, PaymentPurposes2, PaymentPurposes3, PaymentPurposes4, PaymentPurposes5, PaymentPurposes6,
		|PaymentTerm, RankingInPriority,
		|PaymentTerm1, PaymentTerm2, PaymentTerm3,
		|AcceptanceTerm, KindOfLetterOfCredit, PaymentByView, AdditionConditions, PurchaseCommercialInvoiceNumber, DateOfSendingDoc,
		|StatementData
		|");
	
EndFunction

// The structure template that is used when reading extract data from a file
// 
// Returns:
// 	Structure - LongDesc:
// * StartDate - Date - start date of the bank statement period
// * EndDate - Date - end date of the bank statement period
// * CreateAccount_1 - String - the account number for which the statement was generated
// * OpeningBalance - Number - the balance of funds on the account at the beginning of the statement period
// * TotalReceived_ - Number - the amount of funds received for the period
// * TotalDebited - Number - the amount of funds debited from the account for the period
// * ClosingBalance - Number - cash balance at the end of the period.
Function CurrentAccountData_() Export
	
	Return New Structure("
		|StartDate,
		|EndDate,
		|CreateAccount_1,
		|OpeningBalance,
		|TotalReceived_,
		|TotalDebited,
		|ClosingBalance,
		|PersonalAccountSection,
		|PersonalAccountNumber");
	
EndFunction

// Returns an indication of the presence or absence of the account number being checked in the statement file.
// 
// Parameters:
//  Account - FormDataCollectionItem, String - invoice for verification.
//  StatementData - Undefined, Structure - Data obtained from the extract file; can be obtained from the parse file1cclientbankexchange.
// 
// Returns:
//  Boolean - indicates whether or not there is an invoice in the statement file
//
Function ThereIsInvoiceInStatementFile(Account, StatementData) Export

	Result = False;
	
	If TypeOf(StatementData) = Type("Structure") Then
		
		ListOfStatementAccounts = New Array;
		ListOfStatementAccounts = StatementData.AccountList;
		
		If TypeOf(ListOfStatementAccounts) = Type("Array") Then
			
			If TypeOf(Account) = Type("String") Then
				Result = ListOfStatementAccounts.Find(Account) <> Undefined;
			Else
				Result = ListOfStatementAccounts.Find(Account.AccountNumber) <> Undefined;
			EndIf;
			
		EndIf;
		
	EndIf; 
	
	Return Result;

EndFunction

#EndRegion

#Region ManagingFormInterfaceElements

// Configures the properties of form elements
// 
// Parameters:
//     Form - ClientApplicationForm - Form
//     ChangedProps - String - Props whose value has changed
//     AdditionalAttributes - Structure - Contains the names and values of additional details that belong to the form
//
Procedure CustomizeFormElements(Form, ChangedProps = "", AdditionalAttributes = Undefined) Export
	
	PropertiesOfFormElements = PropertiesOfFormElements(Form.Object, Form.FieldSettings, Form.FieldDependencies, ChangedProps, AdditionalAttributes);
	
	For Each ItemProperties In PropertiesOfFormElements Do
		
		If Not ValueIsFilled(ItemProperties.TagName) Then
			Continue;
		EndIf;
		
		TagName = FormItemName(ItemProperties.TagName);
		
		If ItemProperties.Property = "OnlyViewWithoutBlankMark" Then
			Form.Items[TagName].ReadOnly = ItemProperties.Value;
			Form.Items[TagName].AutoMarkIncomplete = Not ItemProperties.Value;
		ElsIf ItemProperties.Property = "OnlyViewWithoutClearing" Then
			Form.Items[TagName].ReadOnly = ItemProperties.Value;
		ElsIf ItemProperties.Property = "ItemVisibility" Then
			Form.Items[TagName].Visible = ItemProperties.Value;
		Else
			Form.Items[TagName][ItemProperties.Property] = ItemProperties.Value;
		EndIf;
		If ItemProperties.Property = "AutoMarkIncomplete" And ItemProperties.Value = False
			Or ItemProperties.Property = "OnlyViewWithoutBlankMark" And ItemProperties.Value = True Then
			Form.Items[TagName].MarkIncomplete = False;
		EndIf;
	EndDo;
	
EndProcedure

// Defines the properties of form elements based on the passed settings
// 
// Parameters:
//     Object - FormDataStructure - form object
//     FieldSettings - See CashServer.InitializeFormFieldSettings
//     FieldDependencies - See CashServer.InitializeDependenciesOfFormFields
//     ChangedProps - String - Name of the changed form details
//     AdditionalAttributes - Structure, Undefined - structure of additional details
//
// Returns:
//  Array of FormField - array of property values for form elements
//
Function PropertiesOfFormElements(Object, FieldSettings, FieldDependencies = Undefined, ChangedProps = "", AdditionalAttributes = Undefined) Export
	
	PropertiesOfFormElements = New Array;
	
	If Not ValueIsFilled(ChangedProps) Or Not ValueIsFilled(FieldDependencies) Then
		
		For Each SettingItem In FieldSettings Do
			
			ConditionValue_ = Undefined;
			
			For Each Field In SettingItem.Fields Do
				
				If ConditionValue_ = Undefined Then
					SettingsElementConditions = SettingItem["Condition"]; // DataCompositionFilter
					ConditionValue_ = ConditionValue_(SettingsElementConditions.Items, Object,, AdditionalAttributes);
				EndIf;
				
				For Each Property In SettingItem.Properties Do
					
					If Property.Value = Undefined
						Or TypeOf(Property.Value) = Type("Boolean") Then
						
						If Property.Value = Undefined Then
							PropertyValue = ConditionValue_;
						ElsIf Property.Value Then
							PropertyValue = ConditionValue_;
						Else
							PropertyValue = Not ConditionValue_;
						EndIf;
						
						AddFormFieldProperty(Field, Property.Key, PropertyValue, PropertiesOfFormElements);
					Else
						If Not ValueIsFilled(ConditionValue_) Or ConditionValue_ Then
							AddFormFieldProperty(Field, Property.Key, Property.Value, PropertiesOfFormElements);
						EndIf;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		
	Else
		
		DependentFields = Undefined;
		
		ChangedBankingDetails = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ChangedProps,,, True);
		
		For Each AttributeValue In ChangedBankingDetails Do
			
			FoundRows = FieldDependencies.FindRows(New Structure("AttributeName", AttributeValue));
			If FoundRows.Count() Then
				DependentFields = FoundRows[0].DependentFields;
			EndIf;
			
			If DependentFields <> Undefined Then
				
				For Each SettingItem In FieldSettings Do
					
					ConditionValue_ = Undefined;
					
					For Each Field In SettingItem.Fields Do
						
						If DependentFields.Find(Field) = Undefined Then
							Continue;
						EndIf;
						
						If ConditionValue_ = Undefined Then
							SettingsElementConditions = SettingItem["Condition"]; // DataCompositionFilter
							ConditionValue_ = ConditionValue_(SettingsElementConditions.Items, Object,, AdditionalAttributes);
						EndIf;
						
						For Each Property In SettingItem.Properties Do
							
							If Property.Value = Undefined
								Or TypeOf(Property.Value) = Type("Boolean") Then
								
								If Property.Value = Undefined Then
									PropertyValue = ConditionValue_;
								ElsIf Property.Value Then
									PropertyValue = ConditionValue_;
								Else
									PropertyValue = Not ConditionValue_;
								EndIf;
								
								AddFormFieldProperty(Field, Property.Key, PropertyValue, PropertiesOfFormElements);
							Else
								If Not ValueIsFilled(ConditionValue_) Or ConditionValue_ Then
									AddFormFieldProperty(Field, Property.Key, Property.Value, PropertiesOfFormElements);
								EndIf;
							EndIf;
						EndDo;
					EndDo;
				EndDo;
			EndIf;
			
		EndDo;
	EndIf;
	
	Return PropertiesOfFormElements;
	
EndFunction

// Fills in the name of the group containing the main bank details
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the bank account of the organization or counterparty.
Procedure FillInMainBankDetails(Form) Export

	UnbreakableGap = Char(160);
	
	If Not ValueIsFilled(Form.Object.Bank) And Not Form.Object.ManualBankDetailsChange Then
		Form.TitlePageBank = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
									|ru = 'Ввести реквизиты банка вручную...';
									|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
									|it = 'Inserire i requisiti bancari manualmente...';
									|pl = 'Wpisz dane banku ręcznie...';
									|tr = 'Banka bilgilerini manuel olarak gir...'");
		Return
	EndIf;
	
	OutputAttributes = New Array;
	HasData = False;
	
	If Form.Object.ManualBankDetailsChange Then
		If Form.NationalBankAccountDetails Then
			If Not IsBlankString(Form.BankDescription) Then
				BankDescription = Form.BankDescription;
				HasData = True;
			ElsIf Form.InternationalBankAccountDetails
				And ValueIsFilled(Form.BankNameInt) Then
				BankDescription = Form.BankNameInt;
			Else
				BankDescription = NStr("vi = '<chưa chỉ ra>';
										|ru = '<не указано>';
										|en = '<none>'; fa = '<هیچ>';
										|it = '<non indicato>';
										|pl = '<nie określono>';
										|tr = '<belirtilmedi>'");
			EndIf;
		Else
			If Not IsBlankString(Form.BankNameInt) Then
				BankDescription = Form.BankNameInt;
				HasData = True;
			Else
				BankDescription = NStr("vi = '<chưa chỉ ra>';
										|ru = '<не указано>';
										|en = '<none>'; fa = '<هیچ>';
										|it = '<non indicato>';
										|pl = '<nie określono>';
										|tr = '<belirtilmedi>'");
			EndIf;
		EndIf;
		OutputAttributes.Add(StrReplace(BankDescription, "", UnbreakableGap));
	EndIf;
	
	If Form.NationalBankAccountDetails Then
		If Not IsBlankString(Form.BankBIC) Then
			BankBIC = TrimAll(Form.BankBIC);
			HasData = True;
		Else
			BankBIC = NStr("vi = '<chưa chỉ ra>';
							|ru = '<не указан>';
							|en = '<not specified>'; fa = '<مشخص نشده>';
							|it = '<non specificato>';
							|pl = '<nie określono>';
							|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(Form.Items.BankBIC.Title + ":" + UnbreakableGap + BankBIC);
	EndIf;
	
	If Form.InternationalBankAccountDetails Then
		If Not IsBlankString(Form.BankSWIFTCode) Then
			BankSWIFTCode = TrimAll(Form.BankSWIFTCode);
			HasData = True;
		Else
			BankSWIFTCode = NStr("vi = '<chưa chỉ ra>';
								|ru = '<не указан>';
								|en = '<not specified>'; fa = '<مشخص نشده>';
								|it = '<non specificato>';
								|pl = '<nie określono>';
								|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(StrReplace(Form.Items.BankSWIFTCode.Title, " ", UnbreakableGap) + ":"
			+ UnbreakableGap + BankSWIFTCode);
			
		If ValueIsFilled(Form.CountryOfBank) Then
			
			HasData = True;
			OutputAttributes.Add(String(Form.CountryOfBank));
			
		EndIf;
		
	EndIf;
	
	If Not Form.Object.DigitalRoubleAccount
			And Form.SettlementBankUsed Then
		Value = ?(Form.Items.BankCorrAccount.Visible, Form.BankCorrAccount, Form.Object.BankAccountForPayments);
		If Not IsBlankString(Value) Then
			Value = TrimAll(Value);
			HasData = True;
		Else
			Value = NStr("vi = '<chưa chỉ ra>';
						|ru = '<не указан>';
						|en = '<not specified>'; fa = '<مشخص نشده>';
						|it = '<non specificato>';
						|pl = '<nie określono>';
						|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(StrReplace(Form.Items.BankCorrAccount.Title, " ", UnbreakableGap) + ":"
			+ UnbreakableGap + Value);
	EndIf;
	
	If Form.Object.ManualBankDetailsChange And Not HasData Then
		Form.TitlePageBank = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
									|ru = 'Ввести реквизиты банка вручную...';
									|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
									|it = 'Inserire i requisiti bancari manualmente...';
									|pl = 'Wpisz dane banku ręcznie...';
									|tr = 'Banka bilgilerini manuel olarak gir...'");
	Else
		Form.TitlePageBank = StrConcat(OutputAttributes, "; ");
		Form.Items.Bank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
										|ru = '<реквизиты банка введены вручную>';
										|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
										|it = '<requisiti bancari inseriti manualmente>';
										|pl = '<dane banku zostały wprowadzone ręcznie>';
										|tr = '<banka bilgileri manuel olarak girildi>'");
	EndIf;
	
EndProcedure

// Fills in the name of the group containing the bank's main payment details
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the bank account of the organization or counterparty.
Procedure FillInMainBankDetailsForSettlements(Form) Export

	UnbreakableGap = Char(160);
	
	If Not ValueIsFilled(Form.Object.TransferBank)
		And Not Form.Object.TransferBankDetailsManualEdit Then
		Form.TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
												|ru = 'Ввести реквизиты банка вручную...';
												|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
												|it = 'Inserire i requisiti bancari manualmente...';
												|pl = 'Wpisz dane banku ręcznie...';
												|tr = 'Banka bilgilerini manuel olarak gir...'");
		Return
	EndIf;
	
	OutputAttributes = New Array;
	HasData = False;
	
	If Form.Object.TransferBankDetailsManualEdit Then
		If Form.NationalBankAccountDetails Then
			If Not IsBlankString(Form.TransferBankDescription) Then
				TransferBankDescription = TrimAll(Form.TransferBankDescription);
				HasData = True;
			ElsIf Form.InternationalBankAccountDetails
				And ValueIsFilled(Form.BankNameForPaymentsInt) Then
				TransferBankDescription = Form.BankNameForPaymentsInt;
			Else
				TransferBankDescription = NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указано>';
												|en = '<none>'; fa = '<هیچ>';
												|it = '<non indicato>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'");
			EndIf;
		Else
			If Not IsBlankString(Form.BankNameForPaymentsInt) Then
				TransferBankDescription = TrimAll(Form.BankNameForPaymentsInt);
				HasData = True;
			Else
				TransferBankDescription = NStr("vi = '<chưa chỉ ra>';
												|ru = '<не указано>';
												|en = '<none>'; fa = '<هیچ>';
												|it = '<non indicato>';
												|pl = '<nie określono>';
												|tr = '<belirtilmedi>'");
			EndIf;
		EndIf;
		OutputAttributes.Add(StrReplace(TransferBankDescription, "", UnbreakableGap));
	EndIf;
	
	If Form.NationalBankAccountDetails Then
		If Not IsBlankString(Form.TransferBankBIC) Then
			TransferBankBIC = TrimAll(Form.TransferBankBIC);
			HasData = True;
		Else
			TransferBankBIC = NStr("vi = '<chưa chỉ ra>';
									|ru = '<не указан>';
									|en = '<not specified>'; fa = '<مشخص نشده>';
									|it = '<non specificato>';
									|pl = '<nie określono>';
									|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(
			Form.Items.TransferBankBIC.Title + ":" + UnbreakableGap + TransferBankBIC);
	EndIf;
	
	If Form.InternationalBankAccountDetails Then
		If Not IsBlankString(Form.BankSWIFTCodeForPayments) Then
			BankSWIFTCodeForPayments = TrimAll(Form.BankSWIFTCodeForPayments);
			HasData = True;
		Else
			BankSWIFTCodeForPayments = NStr("vi = '<chưa chỉ ra>';
											|ru = '<не указан>';
											|en = '<not specified>'; fa = '<مشخص نشده>';
											|it = '<non specificato>';
											|pl = '<nie określono>';
											|tr = '<belirtilmedi>'");
		EndIf;
		OutputAttributes.Add(StrReplace(Form.Items.BankSWIFTCodeForPayments.Title, " ", UnbreakableGap)
			+ ":" + UnbreakableGap + BankSWIFTCodeForPayments);
	EndIf;
	
	If Form.Object.TransferBankDetailsManualEdit And Not HasData Then
		Form.TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
												|ru = 'Ввести реквизиты банка вручную...';
												|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
												|it = 'Inserire i requisiti bancari manualmente...';
												|pl = 'Wpisz dane banku ręcznie...';
												|tr = 'Banka bilgilerini manuel olarak gir...'");
	Else
		Form.TitleBankPageForSettlements = StrConcat(OutputAttributes, "; ");
		Form.Items.TransferBank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
												|ru = '<реквизиты банка введены вручную>';
												|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
												|it = '<requisiti bancari inseriti manualmente>';
												|pl = '<dane banku zostały wprowadzone ręcznie>';
												|tr = '<banka bilgileri manuel olarak girildi>'");
	EndIf;
	
EndProcedure

// Returns a flag for the zero VAT rate.
// 
// Parameters:
//  VATRate - CatalogRef.VATRates - the selected VAT rate.
// 
// Returns:
//  Boolean - indicates that the VAT rate is zero
Function ThisIsZeroVATRATE(VATRate) Export
	
	RatesWithoutVAT = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RatesWithoutVAT.Add(PredefinedValue("Catalog.VATRates.EmptyRef"));
	
	Return RatesWithoutVAT.FindByValue(VATRate) <> Undefined;

EndFunction

#EndRegion

#Region CashForecast

Procedure RecalculateSubordinateTreeRows(TreeRow, PlanningDays) Export
	
	If TreeRow.LineKind = 0 Or TreeRow.LineKind = 4 Then // The balance in the currency of the DS, or in the currency of the payment
		
		OpeningBalance = TreeRow.Balance;
		For Indus = 0 To PlanningDays Do
			ColumnName = "Day" + Indus;
			TreeRow[ColumnName] = OpeningBalance + TreeRow[ColumnName + "InCurrency"];
			OpeningBalance = TreeRow[ColumnName];
			
			If TreeRow.LineKind = 0 Then
				TreeRow[ColumnName + "ErrorCriticalBalance"] = (OpeningBalance <= TreeRow.CriticalBalance)
					And TreeRow.CriticalBalance > 0
					And OpeningBalance > 0;
			EndIf;
		EndDo;
		
		TreeRow.Day0 = TreeRow.Overdue;
		
	ElsIf TreeRow.LineKind = 2 Then // Balance in one currency
		
		TreeRow.Balance = TreeRow.BalanceInASingleCurrency;
		OpeningBalance = TreeRow.BalanceInASingleCurrency;
		For Indus = 0 To PlanningDays Do
			ColumnName = "Day" + Indus;
			TreeRow[ColumnName] = OpeningBalance + TreeRow[ColumnName + "InOneCurrency"];
			OpeningBalance = TreeRow[ColumnName];
		EndDo;
		
		TreeRow.Day0 = TreeRow.OverdueInOneCurrency;
		
	ElsIf TreeRow.LineKind = 1 Then // Turnover in the currency of the DS, or in the currency of payment
		
		For Indus = 0 To PlanningDays Do
			ColumnName = "Day" + Indus;
			TreeRow[ColumnName] = TreeRow[ColumnName + "InCurrency"];
		EndDo;
		
		TreeRow.Day0 = TreeRow.Overdue;
		TreeRow.IrreducibleBalance = 0;
		
	ElsIf TreeRow.LineKind = 3 Then // Turnover in one currency
		
		For Indus = 0 To PlanningDays Do
			ColumnName = "Day" + Indus;
			TreeRow[ColumnName] = TreeRow[ColumnName + "InOneCurrency"];
		EndDo;
		
		TreeRow.Day0 = TreeRow.OverdueInOneCurrency;
		
	EndIf;
	
	If TypeOf(TreeRow) = Type("FormDataTreeItem") Then
		Rows = TreeRow.GetItems();
	Else
		Rows = TreeRow.Rows;
	EndIf;
		
	For Each TreeStringIsChild In Rows Do
		RecalculateSubordinateTreeRows(TreeStringIsChild, PlanningDays);
	EndDo;
	
EndProcedure

Function PaymentDate(PlanFromDate, Day) Export
	
	Return PlanFromDate + 86400 * (Day - 1);
	
EndFunction

Function PaymentDay(PlanFromDate, PaymentDate) Export
	
	If PlanFromDate > PaymentDate Then
		Return 0;
	Else
		Return (PaymentDate - PlanFromDate)/86400 + 1;
	EndIf;
	
EndFunction

#EndRegion

#Region Acquiring

// The function is to calculate the fee amount.
// "Receipt" - the fee has already been deducted from the receipt amount.
// "Write-off" - the fee in the amount of the document.
// "Acquiring operation" - the fee is considered from above.
//
// Parameters:
//  Sum	 - Number - The amount of the document
//  Rate1	 - Number - Fee rate (%)
//  Operation - String - "Receipt", "Return", "Equalizing operation".
// 
// Returns:
//  Number - The amount of the fee.
//
Function CalculateCommissionAmount(Sum, Rate1, Operation = "AcquiringTransaction") Export
	
	If Operation = "Inpayment" Then
		If Rate1 <> 100 Then
			Return Sum * Rate1 / (100 - Rate1);
		Else
			Return Sum;
		EndIf;
	ElsIf Operation = "AcquiringTransaction" Then
		Return Sum / 100 * Rate1;
	ElsIf Operation = "Return" Then
		Return Sum * Rate1 / (100 + Rate1);
	Else
		Raise(NStr("vi = 'Loại giao dịch của dịch vụ thẻ thanh toán không xác định.';
					|ru = 'Неизвестный вид операции эквайринга.';
					|en = 'Unknown acquiring transaction type.'; fa = 'Unknown acquiring transaction type.';
					|it = 'Unknown acquiring transaction type.';
					|pl = 'Unknown acquiring transaction type.';
					|tr = 'Bilinmeyen PoS işlemi türü.'"));
	EndIf;
	
EndFunction

// The function is to calculate the fee rate.
// "Receipt" - the fee has already been deducted from the receipt amount.
// "Write-off" - the fee in the amount of the document.
// "Acquiring operation" - the fee is considered from above.
//
// Parameters:
//  Sum	 - Number - The amount of the document
//  Fee	 - Number - Fee amount
//  Operation - String - "Receipt", "Return", "Equalizing operation".
// 
// Returns:
//  Number - Fee rate.
//
Function CalculateCommissionRate(Sum, Fee, Operation = "AcquiringTransaction") Export
	
	If Operation = "Inpayment" Then
		If Sum <> 0 Or Fee <> 0 Then
			Return Fee / (Sum + Fee) * 100;
		Else
			Return 0;
		EndIf;
	ElsIf Operation = "AcquiringTransaction" Then
		If Sum<>0 Then
			Return Fee / Sum * 100;
		Else
			Return 0;
		EndIf;
	ElsIf Operation = "Return" Then
		If Sum <> 0 Or Fee <> 0 Then
			Return Fee / (Sum - Fee) * 100;
		Else
			Return 0;
		EndIf;
	Else
		Raise(NStr("vi = 'Loại giao dịch của dịch vụ thẻ thanh toán không xác định.';
					|ru = 'Неизвестный вид операции эквайринга.';
					|en = 'Unknown acquiring transaction type.'; fa = 'Unknown acquiring transaction type.';
					|it = 'Unknown acquiring transaction type.';
					|pl = 'Unknown acquiring transaction type.';
					|tr = 'Bilinmeyen PoS işlemi türü.'"));
	EndIf;
	
EndFunction

#EndRegion

#Region ARAPAccounting

Procedure CalculateAmountOfSettlementsInDecryptionLine(TSRow, DocumentCurrency, CurrencyOfComplianceAccounting) Export
	
	If DocumentCurrency = CurrencyOfComplianceAccounting Then
		If TSRow.ExchangeRateNumeratorOfMutualSettlements <> 0 Then
			TSRow.AmountARAP = TSRow.Sum / TSRow.ExchangeRateNumeratorOfMutualSettlements * TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements;
		Else
			TSRow.AmountARAP = 0;
		EndIf;
	Else
		If TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements <> 0 Then
			TSRow.AmountARAP = TSRow.Sum * TSRow.ExchangeRateNumeratorOfMutualSettlements / TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements;
		Else
			TSRow.AmountARAP = 0;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CalculateAmountInDecryptionLine(TSRow, DocumentCurrency, CurrencyOfComplianceAccounting) Export
	
	If DocumentCurrency = CurrencyOfComplianceAccounting Then
		If TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements <> 0 Then
			TSRow.Sum = TSRow.AmountARAP * TSRow.ExchangeRateNumeratorOfMutualSettlements / TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements;
		Else
			TSRow.Sum = 0;
		EndIf;
	Else
		If TSRow.ExchangeRateNumeratorOfMutualSettlements <> 0 Then
			TSRow.Sum = TSRow.AmountARAP / TSRow.ExchangeRateNumeratorOfMutualSettlements * TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements;
		Else
			TSRow.Sum = 0;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region InternationalBankAccounts

Function AccountNumberCorrespondsToBank(AccountNumber, SWIFT) Export
	
	CountryCodeInInvoice = CountryCodeIBAN(AccountNumber);
	CountryCodeInBank = SWIFTCountryCode(SWIFT);
	Return CountryCodeInInvoice = CountryCodeInBank
	
EndFunction

// Checks the length of the IBAN account number
// 
// Parameters:
// 	AccountNumber - String - account number in IBAN format
// Returns:
// 	Boolean - if True, then the length of the number corresponds to the reference data.
Function CorrectIBANLength(AccountNumber) Export
	
	AccountNumber = TrimAll(AccountNumber);
	
	If Not ValueIsFilled(AccountNumber) Then
		Return False;
	EndIf;
	IBANAccountParameters = IBANAccountParameters();
	CountryCode = CountryCodeIBAN(AccountNumber);
	AccountLength = IBANAccountParameters.Get(CountryCode);
	Return AccountLength = StrLen(AccountNumber)
	
EndFunction

// The function checks the checksum in the IBAN account.
// The verification algorithm is described in ECBS EBS204 v.3.1. (August 2002), page 12.
//
// Parameters:
//  IBAN - String - the account number in the IBAN format to be checked.
// 
// Returns:
//  Boolean - A sign of IBAN correctness
//
Function ValidIBANControlKey(IBAN) Export
	
	// Preliminary stage. We remove unnecessary spaces in the IBAN because it can be specified in paper format.
	VerifiableIBAN  = StrReplace(IBAN, " ", "");
	
	// 1. Move the first 4 characters to the right side of the IBAN.
	VerifiableIBAN = Mid(VerifiableIBAN, 5) + Left(VerifiableIBAN, 4);
	
	// 2. Convert letters to numbers according to the conversion table.
	// 
	// A = 10  G = 16  M = 22  S = 28  Y = 34
	// B = 11  H = 17  N = 23  T = 29  Z = 35
	// C = 12  I = 18  O = 24  U = 30
	// D = 13  J = 19  P = 25  V = 31
	// E = 14  K = 20  Q = 26  W = 32
	// F = 15  L = 21  R = 27  X = 33
	
	LettersToConvert = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	For LetterIndex = 1 To StrLen(LettersToConvert) Do
		
		ConvertibleLetter = Mid(LettersToConvert, LetterIndex, 1);
		ConvertibleDigit = LetterIndex + 9;
		
		VerifiableIBAN = StrReplace(VerifiableIBAN, ConvertibleLetter, ConvertibleDigit);
		
	EndDo;
	
	BalanceCheckedByIBAN = VerifiableIBAN;
	LengthOfSegmentBeingChecked = 9;
	NumberType = New TypeDescription("Number",,, New NumberQualifiers(LengthOfSegmentBeingChecked,0));
	ChecksumDigit = 0;
	CheckDigitString = "";
	// IBAN requires a number up to 34 characters long, and the web client supports a number up to 10 characters long,
	// so we split the string into numbers of 9 characters.
	While Not IsBlankString(BalanceCheckedByIBAN) Do
		
		CountOfCharacters = Min(LengthOfSegmentBeingChecked - StrLen(CheckDigitString),
			StrLen(BalanceCheckedByIBAN));
		
		VerifiableIBANString = String(CheckDigitString) + Mid(BalanceCheckedByIBAN, 1, CountOfCharacters);
		
		VerifiableIBANNumber = NumberType.AdjustValue(VerifiableIBANString);
		
		// 3. Apply Mod 97-10 (ISO 7064).
		// If the remainder is equal to 1, then
		// this is a sign that the account is correct.
		ChecksumDigit = VerifiableIBANNumber % 97;
		
		CheckDigitString = String(ChecksumDigit);
		BalanceCheckedByIBAN = Mid(BalanceCheckedByIBAN, CountOfCharacters +1);
		
	EndDo;
	
	Return ChecksumDigit = 1;
	
EndFunction

// Retrieves the country code from the IBAN account number
// 
// Parameters:
// 	IBANAccountNumber - String - account number in IBAN format
// Returns:
// 	String - Country code
Function CountryCodeIBAN(IBANAccountNumber) Export
	
	Return Left(IBANAccountNumber, 2);
	
EndFunction

#EndRegion

#Region BankAccounts

// Fills in the bank account data in the structure according to the source Form.
//
// Parameters:
//  InvoiceData - See NewBankAccountData.
//  Source - ClientApplicationForm - Source Form to fill in.
//  Suffix - String - addition to the Attribute name on the Form.
//
Procedure FillInDetailsOfBankAccount(InvoiceData, Source, Suffix) Export

	If InvoiceData = Undefined Then
		InvoiceData = NewBankAccountData();
	EndIf;
	
	If Suffix <> "" Then
		
		Result = New Map;
		
		For Each InvoiceItem In InvoiceData Do
			Result.Insert(InvoiceItem.Key, InvoiceItem.Key + Suffix);
		EndDo;
	
		For Each ResultItem In Result Do
			InvoiceData[ResultItem.Key] = Source[ResultItem.Value];
		EndDo;
		
	Else
		FillPropertyValues(InvoiceData, Source);
	EndIf;

EndProcedure

// Returns an empty default bank account data structure.
// 
// Returns:
//  Structure - account data:
//  * AccountNumber - String - account number.
//  * ThisIsAnIBAN - Boolean - the IBAN account attribute.
//  * CountryOfBank - CatalogRef.WorldCountries - bank country.
//
Function NewBankAccountData() Export

	Attributes = New Structure;
	Attributes.Insert("AccountNumber", "");
	Attributes.Insert("ThisIsAnIBAN", False);
	Attributes.Insert("CountryOfBank", PredefinedValue("Catalog.WorldCountries.EmptyRef"));
	
	Return Attributes;

EndFunction

// Clears bank details on the form.
//
// Parameters:
//  Form - ClientApplicationForm - The Form on which the cleaning is performed.
//  BankAttributes - String, Structure - list of bank Attributes.
//  This Bank for settlements is a Boolean sign of the bank's Attributes for settlements.
//  This is the head Counter-Boolean attribute of the Attributes of the bank of the main counterparty.
//
Procedure ClearBankDetailsOnForm(Form, Val BankAttributes) Export

	If TypeOf(BankAttributes) = Type("String") Then
		BankAttributes = New Structure(BankAttributes);
	EndIf;
	
	For Each KeyAndValue In BankAttributes Do
		Form[KeyAndValue.Key] = "";
	EndDo;

EndProcedure

// Returns a string of bank Attributes.
// 
// Parameters:
//  FullList - Boolean - a flag that forms a string with all the bank's Attributes.
//  ThisIsBankForSettlements - Boolean - indicates whether a list of bank Attributes is generated for payments.
// 
// Returns:
//  String - Bank Attributes
//
Function BankingDetails(FullList = False, ThisIsBankForSettlements = False) Export
	
	If ThisIsBankForSettlements Then
		AttributesNames = "TransferBankBIC, BankSWIFTCodeForPayments, TransferBankDescription,
		| BankNameForPaymentsInt, TransferBankCorrAccount,
		| TransferBankCity, BankCityForPaymentsInt, TransferBankAddress,
		| BankAddressForPaymentInt, TransferBankPhones";
	Else
		AttributesNames = "BankBIC, BankSWIFTCode, BankDescription, BankNameInt, BankCorrAccount,
		|BankCity, BankCityInt, BankAddress, BankAddressInt, BankPhones";
	EndIf;
	
	If FullList Then
		
		If ThisIsBankForSettlements Then
			AttributesNames = StrTemplate("%1, CountryOfBankForPayments", AttributesNames);
		Else
			AttributesNames = StrTemplate("%1, CountryOfBank", AttributesNames);
		EndIf;
		
	EndIf;
	
	Return AttributesNames;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region AnalysisOfStatement

Procedure LoadTitleBar(TitleBarText, CurrentRow, StatementTitle, TitlesMap)
	
	If TypeOf(StatementTitle) = Type("Undefined") Then
		StatementTitle = New Structure(
			Upper("FormatVersion, Encoding, Sender, Recipient, CreationDate, CreationTime, StartDate, EndDate"));
	EndIf;
	
	Value = ""; Tag_ = "";
	
	If ParseTagString(TitleBarText, Tag_, Value) Then
		
		If TitlesMap.Get(Tag_) <> Undefined Then
		
			If StatementTitle.Property(TitlesMap[Tag_]) Then
				StatementTitle[TitlesMap[Tag_]] = Value;
			EndIf;
		
		EndIf;
		
	EndIf;
	
	StatementTitle.StartDate = GetDateFromString(StatementTitle.StartDate);
	StatementTitle.EndDate = GetDateFromString(StatementTitle.EndDate);
	
EndProcedure

Function LoadInvoicePaymentSection(CurrentRow, RowsCount, RowsArray, TitlesMap)
	
	CurrentAccountTags = CurrentAccountData_();
	
	ParseString = GetImportString(CurrentRow, RowsCount, RowsArray);
	
	Value = ""; Tag_ = "";
	
	While ParseTagString(ParseString, Tag_, Value) Do
		
		If TitlesMap.Get(Tag_) <> Undefined Then
			
			If CurrentAccountTags.Property(TitlesMap[Tag_]) Then
				CurrentAccountTags[TitlesMap[Tag_]] = Value;
			EndIf;
			
		EndIf;
		
		ParseString = GetImportString(CurrentRow, RowsCount, RowsArray);
		
		Value = ""; Tag_ = "";
		
	EndDo;
	
	If Upper(Left(TrimAll(ParseString), 13)) = "КОНЕЦРАСЧСЧЕТ" Then //@NON-NLS-1
		Return CurrentAccountTags;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure LoadSectionOfDocument(DocumentLine, CurrentRow, RowsCount, RowsArray, TitlesMap)
	
	DocumentSection = "СЕКЦИЯДОКУМЕНТ=" + DocumentLine.Operation + Chars.LF; //@NON-NLS-1
	
	ParseString = GetImportString(CurrentRow, RowsCount, RowsArray);
	
	While Left(Upper(TrimAll(ParseString)), 14) <> "КОНЕЦДОКУМЕНТА" Do //@NON-NLS-1
		Tag_      = "";
		Value = "";
		
		If ParseTagString(ParseString, Tag_, Value) Then
			
			DocumentSection = DocumentSection + ParseString + Chars.LF;
			
			If TitlesMap.Get(Tag_) <> Undefined Then
			
				If DocumentLine.Property(TitlesMap[Tag_]) Then
					
					If ValueIsFilled(Value) And Not ValueIsFilled(DocumentLine[TitlesMap[Tag_]]) Then
						DocumentLine[TitlesMap[Tag_]] = Value;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ParseString = GetImportString(CurrentRow, RowsCount, RowsArray);
		
	EndDo;
	
	DocumentLine.StatementData = DocumentSection + "КОНЕЦДОКУМЕНТА"; //@NON-NLS-1
	
EndProcedure

Function GetImportString(CurrentRow, RowsCount, RowsArray)
	
	Buffer = "";
	
	While IsBlankString(Buffer) Or Left(Buffer, 2) = "//" Do
		
		If CurrentRow > RowsCount Then
			Return "";
		EndIf;
		
		Buffer = RowsArray[CurrentRow - 1];
		CurrentRow = CurrentRow + 1;
		
	EndDo;
	
	Return Buffer;
	
EndFunction

Function ParseTagString(ParseString, Tag_, Value)
	
	AssignmentPosition = StrFind(ParseString, "=");
	
	If AssignmentPosition = 0 Then
		Return False;
	EndIf;
	
	Tag_ = Upper(TrimAll(Left(ParseString, AssignmentPosition - 1)));
	
	Value = TrimAll(Mid(ParseString, AssignmentPosition + 1));
	
	Return Not IsBlankString(Tag_);
	
EndFunction

Function RelationOfStatementTagsToKeys()
	
	Link = New Map;
	Link.Insert(Upper("ВерсияФормата"),		"FormatVersion"); //@NON-NLS-1
	Link.Insert(Upper("Кодировка"),			"Encoding"); //@NON-NLS-1
	Link.Insert(Upper("Отправитель"),			"Sender"); //@NON-NLS-1
	Link.Insert(Upper("Получатель"),			"Recipient"); //@NON-NLS-1
	Link.Insert(Upper("ДатаСоздания"),		"CreationDate"); //@NON-NLS-1
	Link.Insert(Upper("ВремяСоздания"),		"CreationTime"); //@NON-NLS-1
	Link.Insert(Upper("ДатаНачала"),			"StartDate"); //@NON-NLS-1
	Link.Insert(Upper("ДатаКонца"),			"EndDate"); //@NON-NLS-1
	Link.Insert(Upper("РасчСчет"),			"CreateAccount_1"); //@NON-NLS-1
	Link.Insert(Upper("НачальныйОстаток"),	"OpeningBalance"); //@NON-NLS-1
	Link.Insert(Upper("ВсегоПоступило"),		"TotalReceived_"); //@NON-NLS-1
	Link.Insert(Upper("ВсегоСписано"),		"TotalDebited"); //@NON-NLS-1
	Link.Insert(Upper("КонечныйОстаток"),		"ClosingBalance"); //@NON-NLS-1
	Link.Insert(Upper("Номер"),				"Number"); //@NON-NLS-1
	Link.Insert(Upper("Дата"),				"Date"); //@NON-NLS-1
	Link.Insert(Upper("Сумма"),				"Sum"); //@NON-NLS-1
	Link.Insert(Upper("ВидПлатежа"),			"PaymentKind"); //@NON-NLS-1
	Link.Insert(Upper("ВидОплаты"),			"PaymentKind_"); //@NON-NLS-1
	Link.Insert(Upper("Операция"),			"Operation"); //@NON-NLS-1
	Link.Insert(Upper("КвитанцияДата"),		"ReceiptDate"); //@NON-NLS-1
	Link.Insert(Upper("КвитанцияВремя"),		"ReceiptTime"); //@NON-NLS-1
	Link.Insert(Upper("КвитанцияСодержание"),	"ReceiptContent"); //@NON-NLS-1
	Link.Insert(Upper("ДатаСписано"),			"DepartureDate"); //@NON-NLS-1
	Link.Insert(Upper("ДатаПоступило"),		"ArrivalDate_"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикСчет"),		"PayerAccount"); //@NON-NLS-1
	Link.Insert(Upper("Плательщик"),			"Payer"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикИНН"),		"PayerTIN"); //@NON-NLS-1
	Link.Insert(Upper("Плательщик1"),			"Payer1"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикНаименованиеМеждународное"),	"PayerInternationalName"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикСтрана"),	"PayerCountry"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикРасчСчет"),	"PayerBankAccount"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБанк1"),		"PayerBank_1"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБанк2"),		"PayerBank_2"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБИК"),		"PayerBIC"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикКорсчет"),	"PayerCorAccount"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБанк3"),		"PayerBank_3"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБанк4"),		"PayerBank_4"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикБанк5"),		"PayerBank_5"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикСВИФТ"),		"PayerSWIFT"); //@NON-NLS-1
	Link.Insert(Upper("Плательщик2"),			"Payer2"); //@NON-NLS-1
	Link.Insert(Upper("Плательщик3"),			"Payer3"); //@NON-NLS-1
	Link.Insert(Upper("Плательщик4"),			"Payer4"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательСчет"),		"BeneficiaryAccount"); //@NON-NLS-1
	Link.Insert(Upper("Получатель"),			"Recipient"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательИНН"),		"BeneficiaryTIN"); //@NON-NLS-1
	Link.Insert(Upper("Получатель1"),			"Recipient1"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательНаименованиеМеждународное"),	"RecipientInternationalName"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательСтрана"),	"RecipientCountry"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательРасчСчет"),	"RecipientBankAccount"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБанк1"),		"RecipientBank_1"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБанк2"),		"RecipientBank_2"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБИК"),		"BeneficiaryBIC"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательКорсчет"),	"BeneficiaryCorAccount"); //@NON-NLS-1
	Link.Insert(Upper("Получатель2"),			"Recipient2"); //@NON-NLS-1
	Link.Insert(Upper("Получатель3"),			"Recipient3"); //@NON-NLS-1
	Link.Insert(Upper("Получатель4"),			"Recipient4"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБанк3"),		"RecipientBank_3"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБанк4"),		"RecipientBank_4"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательБанк5"),		"RecipientBank_5"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательСВИФТ"),		"BeneficiarySWIFT"); //@NON-NLS-1
	Link.Insert(Upper("СтатусСоставителя"),	"AuthorStatus"); //@NON-NLS-1
	Link.Insert(Upper("ПлательщикКПП"),		"KPPPayer"); //@NON-NLS-1
	Link.Insert(Upper("ПолучательКПП"),		"BeneficiaryCRTR"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательКБК"),		"IndicatorBCC"); //@NON-NLS-1
	Link.Insert(Upper("ОКАТО"),				"RNCPS"); //@NON-NLS-1
	Link.Insert(Upper("ОКТМО"),				"MUNICIPALTERRITORIESCLASSIFIER"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательОснования"),	"BasisIndicator"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательПериода"),	"PeriodIndicator"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательНомера"),	"NumberIndicator"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательДаты"),		"DateIndicator"); //@NON-NLS-1
	Link.Insert(Upper("ПоказательТипа"),		"TypeIndicator"); //@NON-NLS-1
	Link.Insert(Upper("Код"),					"Code"); //@NON-NLS-1
	Link.Insert(Upper("КодНазПлатежа"),		"PaymentPurposeCode"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа"),	"PaymentPurposes"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа1"),	"PaymentPurposes1"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа2"),	"PaymentPurposes2"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа3"),	"PaymentPurposes3"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа4"),	"PaymentPurposes4"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа5"),	"PaymentPurposes5"); //@NON-NLS-1
	Link.Insert(Upper("НазначениеПлатежа6"),	"PaymentPurposes6"); //@NON-NLS-1
	Link.Insert(Upper("СрокПлатежа"),			"PaymentTerm"); //@NON-NLS-1
	Link.Insert(Upper("Очередность"),			"RankingInPriority"); //@NON-NLS-1
	Link.Insert(Upper("УсловиеОплаты1"),		"PaymentTerm1"); //@NON-NLS-1
	Link.Insert(Upper("УсловиеОплаты2"),		"PaymentTerm2"); //@NON-NLS-1
	Link.Insert(Upper("УсловиеОплаты3"),		"PaymentTerm3"); //@NON-NLS-1
	Link.Insert(Upper("СрокАкцепта"),			"AcceptanceTerm"); //@NON-NLS-1
	Link.Insert(Upper("ВидАккредитива"),		"KindOfLetterOfCredit"); //@NON-NLS-1
	Link.Insert(Upper("ПлатежПоПредст"),		"PaymentByView"); //@NON-NLS-1
	Link.Insert(Upper("ДополнУсловия"),		"AdditionConditions"); //@NON-NLS-1
	Link.Insert(Upper("НомерСчетаПоставщика"),"PurchaseCommercialInvoiceNumber"); //@NON-NLS-1
	Link.Insert(Upper("ДатаОтсылкиДок"),		"DateOfSendingDoc"); //@NON-NLS-1
	Link.Insert(Upper("ДанныеВыписки"),		"StatementData"); //@NON-NLS-1
	
	Return Link;
	
EndFunction

#EndRegion

#Region ManagingFormInterfaceElements

Procedure AddFormFieldProperty(TagName, Property, Value, PropertiesOfFormFields)
	
	NewProperty = New Structure;
	NewProperty.Insert("TagName", TagName);
	NewProperty.Insert("Property", Property);
	NewProperty.Insert("Value", Value);
	
	PropertiesOfFormFields.Add(NewProperty);
	
EndProcedure

Function ConditionValue_(ConditionElements, Object, GroupType = Undefined, AdditionalAttributes = Undefined)
	
	If GroupType = Undefined Then
		GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	EndIf;
	
	Value = Undefined;
	
	For Each ConditionElement In ConditionElements Do
		If TypeOf(ConditionElement) = Type("DataCompositionFilterItemGroup") Then
			If GroupType = DataCompositionFilterItemsGroupType.AndGroup Then
				
				If Value = Undefined Then
					Value = True;
				EndIf;
				Value = Value And ConditionValue_(ConditionElement.Items, Object, ConditionElement.GroupType, AdditionalAttributes);
				
			ElsIf GroupType = DataCompositionFilterItemsGroupType.OrGroup Then
				
				If Value = Undefined Then
					Value = False;
				EndIf;
				Value = Value Or ConditionValue_(ConditionElement.Items, Object, ConditionElement.GroupType, AdditionalAttributes);
				
			ElsIf GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
				
				Value = Not ConditionValue_(ConditionElement.Items, Object, ConditionElement.GroupType, AdditionalAttributes);
				
			EndIf;
		Else
			If GroupType = DataCompositionFilterItemsGroupType.AndGroup Then
				
				If Value = Undefined Then
					Value = True;
				EndIf;
				Value = Value And ValueOfConditionExpression(ConditionElement, Object, AdditionalAttributes);
				
			ElsIf GroupType = DataCompositionFilterItemsGroupType.OrGroup Then
				
				If Value = Undefined Then
					Value = False;
				EndIf;
				Value = Value Or ValueOfConditionExpression(ConditionElement, Object, AdditionalAttributes);
				
			ElsIf GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
				
				Value = Not ValueOfConditionExpression(ConditionElement, Object, AdditionalAttributes);
				
			EndIf;
		EndIf;
	EndDo;
	
	Return Value;
	
EndFunction

Function ValueOfConditionExpression(ConditionElement, Object, AdditionalAttributes)
	
	Value = False;
	
	LeftValue = Undefined;
	RightValue = Undefined;
	
	AttributeName = String(ConditionElement.LeftValue);
	If TypeOf(AdditionalAttributes) = Type("Structure") Then
		PointPosition = StrFind(AttributeName, ".");
		If PointPosition <> 0 Then
			AdditionalAttributes.Property(Mid(AttributeName, PointPosition + 1), LeftValue);
		Else
			LeftValue = Object[AttributeName];
		EndIf;
	Else
		LeftValue = Object[AttributeName];
	EndIf;
	
	If TypeOf(ConditionElement.RightValue) = Type("DataCompositionField") Then
		AttributeName = String(ConditionElement.RightValue);
		If TypeOf(AdditionalAttributes) = Type("Structure") Then
			PointPosition = StrFind(AttributeName, ".");
			If PointPosition <> 0 Then
				AdditionalAttributes.Property(Mid(AttributeName, PointPosition + 1), RightValue);
			Else
				RightValue = Object[AttributeName];
			EndIf;
		Else
			RightValue = Object[AttributeName];
		EndIf;
	Else
		RightValue = ConditionElement.RightValue;
	EndIf;
	
	If LeftValue <> Undefined Then
		If ConditionElement.ComparisonType = DataCompositionComparisonType.Equal Then
			Value = (LeftValue = RightValue);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.NotEqual Then
			Value = (LeftValue <> RightValue);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.Filled Then
			Value = ValueIsFilled(LeftValue);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.NotFilled Then
			Value = Not ValueIsFilled(LeftValue);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.InList And TypeOf(RightValue) = Type("Array") Then
			Value = (Not RightValue.Find(LeftValue) = Undefined);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.InList And TypeOf(RightValue) = Type("ValueList") Then
			Value = (Not RightValue.FindByValue(LeftValue) = Undefined);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.NotInList And TypeOf(RightValue) = Type("Array") Then
			Value = (RightValue.Find(LeftValue) = Undefined);
		ElsIf ConditionElement.ComparisonType = DataCompositionComparisonType.NotInList And TypeOf(RightValue) = Type("ValueList") Then
			Value = (RightValue.FindByValue(LeftValue) = Undefined);
		EndIf;
	EndIf;
	
	Return Value;
	
EndFunction

Function FormItemName(AttributeName)
	
	If AttributeName = "ARAPDetails.PaymentRequest" Then
		Return "ARAPDetailsPaymentRequest"
	ElsIf AttributeName = "ARAPDetails.Department" Then
		Return "ARAPDetailsDepartment"
	ElsIf AttributeName = "ARAPDetails.LineOfBusiness" Then
		Return "ARAPDetailsLineOfBusiness"
	ElsIf AttributeName = "ARAPDetails.CashFlowItem" Then
		Return "ARAPDetailsCashFlowItem"
	ElsIf AttributeName = "ARAPDetails.AmountARAP" Then
		Return "ARAPDetailsAmountARAP"
	ElsIf AttributeName = "ARAPDetails.ARAPCurrency" Then
		Return "ARAPDetailsARAPCurrency"
	ElsIf AttributeName = "ARAPDetails.TransactionRate" Then
		Return "TranscriptOfPaymentSettlementRate"
	ElsIf AttributeName = "ARAPDetails.SettlementRateText" Then
		Return "TranscriptOfPaymentSettlementRateText"
	ElsIf AttributeName = "ARAPDetails.VATAmount" Then
		Return "ARAPDetailsVATAmount"
	ElsIf AttributeName = "ARAPDetails.VATRate" Then
		Return "ARAPDetailsVATRate"
	ElsIf AttributeName = "ARAPDetails.ARAPObject" Then
		Return "ARAPDetailsARAPObject"
	ElsIf AttributeName = "ARAPDetails.Partner" Then
		Return "ARAPDetailsPartner"
	ElsIf AttributeName = "ARAPDetails.LoanDepositContract" Then
		Return "ARAPDetailsLoanDepositContract"
	ElsIf AttributeName = "ARAPDetails.LoanAndDepositAmountType" Then
		Return "ARAPDetailsLoanAndDepositAmountType"
	ElsIf AttributeName = "ARAPDetails.EmployeeLoanAgreement" Then
		Return "ARAPDetailsEmployeeLoanAgreement"
	ElsIf AttributeName = "ARAPDetails.LeaseContracts" Then
		Return "ARAPDetailsLeaseContracts"
	ElsIf AttributeName = "ARAPDetails.TypeOfLeasePayment" Then
		Return "ARAPDetailsTypeOfLeasePayment"
	ElsIf AttributeName = "ARAPDetails.Organization" Then
		Return "ARAPDetailsOrganization"
	Else
		Return StrReplace(AttributeName, ".", "");
	EndIf;
	
EndFunction

#EndRegion

#Region InternationalBankAccounts

// Gets the country code from SWIFT according to ISO 9362.
//
// Parameters:
//  SWIFTBIC - String - SWIFT BIC code.
// 
// Returns:
//  String -  SWIFT country code.
//
Function SWIFTCountryCode(SWIFTBIC)
	
	Return Mid(SWIFTBIC,5,2);
	
EndFunction

// Returns IBAN prefixes and lengths
// 
// Returns:
//  Map - contains fields:
//    * Key - String - number prefix
//    * Value - Number - the length of the number.
// 
Function IBANAccountParameters()
	
	ReturnCompliance = New Map;
	ReturnCompliance.Insert("AD", 24);
	ReturnCompliance.Insert("AE", 23);
	ReturnCompliance.Insert("AL", 28);
	ReturnCompliance.Insert("AT", 20);
	ReturnCompliance.Insert("AZ", 28);
	ReturnCompliance.Insert("BA", 20);
	ReturnCompliance.Insert("BE", 16);
	ReturnCompliance.Insert("BG", 22);
	ReturnCompliance.Insert("BH", 22);
	ReturnCompliance.Insert("BI", 27);
	ReturnCompliance.Insert("BR", 29);
	ReturnCompliance.Insert("BY", 28);
	ReturnCompliance.Insert("CH", 21);
	ReturnCompliance.Insert("CR", 22);
	ReturnCompliance.Insert("CY", 28);
	ReturnCompliance.Insert("CZ", 24);
	ReturnCompliance.Insert("DE", 22);
	ReturnCompliance.Insert("DJ", 27);
	ReturnCompliance.Insert("DK", 18);
	ReturnCompliance.Insert("DO", 28);
	ReturnCompliance.Insert("EE", 20);
	ReturnCompliance.Insert("EG", 29);
	ReturnCompliance.Insert("ES", 24);
	ReturnCompliance.Insert("FI", 18);
	ReturnCompliance.Insert("FK", 18);
	ReturnCompliance.Insert("FO", 18);
	ReturnCompliance.Insert("FR", 27);
	ReturnCompliance.Insert("GB", 22);
	ReturnCompliance.Insert("GE", 22);
	ReturnCompliance.Insert("GI", 23);
	ReturnCompliance.Insert("GL", 18);
	ReturnCompliance.Insert("GR", 27);
	ReturnCompliance.Insert("GT", 28);
	ReturnCompliance.Insert("HR", 21);
	ReturnCompliance.Insert("HU", 28);
	ReturnCompliance.Insert("IE", 22);
	ReturnCompliance.Insert("IL", 23);
	ReturnCompliance.Insert("IQ", 23);
	ReturnCompliance.Insert("IS", 26);
	ReturnCompliance.Insert("IT", 27);
	ReturnCompliance.Insert("JO", 30);
	ReturnCompliance.Insert("KW", 30);
	ReturnCompliance.Insert("KZ", 20);
	ReturnCompliance.Insert("LB", 28);
	ReturnCompliance.Insert("LC", 32);
	ReturnCompliance.Insert("LI", 21);
	ReturnCompliance.Insert("LT", 20);
	ReturnCompliance.Insert("LU", 20);
	ReturnCompliance.Insert("LV", 21);
	ReturnCompliance.Insert("LY", 25);
	ReturnCompliance.Insert("MC", 27);
	ReturnCompliance.Insert("MD", 24);
	ReturnCompliance.Insert("ME", 22);
	ReturnCompliance.Insert("MK", 19);
	ReturnCompliance.Insert("MN", 20);
	ReturnCompliance.Insert("MR", 27);
	ReturnCompliance.Insert("MT", 31);
	ReturnCompliance.Insert("MU", 30);
	ReturnCompliance.Insert("NI", 28);
	ReturnCompliance.Insert("NL", 18);
	ReturnCompliance.Insert("NO", 15);
	ReturnCompliance.Insert("OM", 23);
	ReturnCompliance.Insert("PK", 24);
	ReturnCompliance.Insert("PL", 28);
	ReturnCompliance.Insert("PS", 29);
	ReturnCompliance.Insert("PT", 25);
	ReturnCompliance.Insert("QA", 29);
	ReturnCompliance.Insert("RO", 24);
	ReturnCompliance.Insert("RS", 22);
	ReturnCompliance.Insert("RU", 33);
	ReturnCompliance.Insert("SA", 24);
	ReturnCompliance.Insert("SC", 31);
	ReturnCompliance.Insert("SD", 18);
	ReturnCompliance.Insert("SE", 24);
	ReturnCompliance.Insert("SI", 19);
	ReturnCompliance.Insert("SK", 24);
	ReturnCompliance.Insert("SM", 27);
	ReturnCompliance.Insert("SO", 23);
	ReturnCompliance.Insert("ST", 25);
	ReturnCompliance.Insert("SV", 28);
	ReturnCompliance.Insert("TL", 23);
	ReturnCompliance.Insert("TN", 24);
	ReturnCompliance.Insert("TR", 26);
	ReturnCompliance.Insert("UA", 29);
	ReturnCompliance.Insert("VA", 22);
	ReturnCompliance.Insert("VG", 24);
	ReturnCompliance.Insert("XK", 20);
	Return ReturnCompliance;
	
EndFunction

#EndRegion

#EndRegion
