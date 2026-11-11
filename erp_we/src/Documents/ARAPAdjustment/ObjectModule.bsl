#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	// Let's clear the tabular part of the document.
	If Debt_.Count() > 0 Then
		Debt_.Clear();
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Debt_");
	
	ARAPAdjustmentLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
	OldVersionOfTransactions = False;

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("DiscrepancyCertificate") Then
		
		FillInOnBasisOfActOfDiscrepancies(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("Claim") Then

		FillInBasedOnClaim(FillingData);

	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		ThisIsAccrual = True;
		AttributesNames = "Organization,Counterparty,Partner,Currency,DocumentAmount,Department,ARAPObject";
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData,AttributesNames);
		FillPropertyValues(ThisObject, DetailsOfFoundation, "Organization,Counterparty");
		NewRow = Debt_.Add();
		NewRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		NewRow.Partner = DetailsOfFoundation.Partner;
		NewRow.ARAPCurrency = DetailsOfFoundation.Currency;
		NewRow.Sum = DetailsOfFoundation.DocumentAmount;
		AddExpensesForGoods = Documents.ARAPAdjustment.AdditionalCostsForReturnsToSupplier(DetailsOfFoundation.Organization, DetailsOfFoundation.Counterparty, FillingData);
		AdditExpenseAmount = AddExpensesForGoods.Total("AdditExpenseAmount");
		If AdditExpenseAmount > 0 Then
			NewRow.Sum = AdditExpenseAmount;
		EndIf;
		NewRow.ARAPObject = DetailsOfFoundation.ARAPObject;
		
		NewRow = IncomeExpensesAssetsLiabilities.Add();
		NewRow.Department = DetailsOfFoundation.Department;
		NewRow.Currency = DetailsOfFoundation.Currency;
		NewRow.Sum = DetailsOfFoundation.DocumentAmount;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(FillingData) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		AttributesNames = "Organization,Counterparty,Department,ARAPCurrency";
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, AttributesNames);
		FillPropertyValues(ThisObject, DetailsOfFoundation, "Organization,Counterparty");
		BusinessOperation = Enums.BusinessTransactions.APWriteOff;
		CorrespondenceWithIncome = True;
		
		RemainingDebt = BalanceOfDebtOnSettlementObject(FillingData);
		For Each Balance In RemainingDebt Do
			NewRow = Debt_.Add();
			FillPropertyValues(NewRow, Balance);
		EndDo;
		
		NewRow = IncomeExpensesAssetsLiabilities.Add();
		NewRow.Department = DetailsOfFoundation.Department;
		NewRow.Currency = DetailsOfFoundation.ARAPCurrency;
		NewRow.Sum = Debt_.Total("Sum");
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		FillByStructure(FillingData);
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation, CorrespondenceWithIncome);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAdjustmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If IntercompanyARAP Then
		NotCheckedAttributeArray.Add("Debt_.Partner");
	EndIf;
	
	If IncomeExpensesAssetsLiabilities.Count() = 1 Then
		NotCheckedAttributeArray.Add("IncomeExpensesAssetsLiabilities.Sum");
		NotCheckedAttributeArray.Add("IncomeExpensesAssetsLiabilities.Currency");
	EndIf;
		
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If ValueIsFilled(Organization) And ValueIsFilled(Counterparty) And (Organization=Counterparty) Then
		Text = NStr("vi = 'Doanh nghiệp và %Counterparty% phải khác nhau.';
					|ru = 'Организация и %Counterparty% должны различаться.';
					|en = 'Company and %Counterparty% should be different.'; fa = 'Company and %Counterparty% should be different.';
					|it = 'La società e %Counterparty% devono differire.';
					|pl = 'Firma i %Counterparty% powinni się różnić';
					|tr = 'İş yeri ve %Counterparty% farklı olmalı.'");
		
		DebtType = ?(BusinessOperation = Enums.BusinessTransactions.APWriteOff,
												Enums.DebtTypes.AccountsPayableType,
												Enums.DebtTypes.AccountsReceivableType);
		
		Text = StrReplace(Text,"%Counterparty%",Enums.DebtTypes.SynonymOfCounterparty(DebtType));
		Common.MessageToUser(Text,ThisObject,"Counterparty",,Cancel);
	EndIf;
	
	If IncomeExpensesAssetsLiabilities.Count() > 1
		And Debt_.Total("Sum") <> IncomeExpensesAssetsLiabilities.Total("Sum") Then
		Text = NStr("vi = 'Tổng số tiền theo các dạng không trùng với số tiền công nợ được điều chỉnh.';
					|ru = 'Итоговая сумма по статьям не совпадает с суммой корректируемой задолженности.';
					|en = 'Total items amount does not match the AR/AP amount to adjust.'; fa = 'Total items amount does not match the AR/AP amount to adjust.';
					|it = 'L''importo complessivo in base alle voci non corrisponde all''importo del debito rettificato.';
					|pl = 'Wartość brutto według pozycji nie jest zgodna z wartością korygowanego zadłużenia.';
					|tr = 'Kalemlerin toplam tutarı, düzeltilen borç tutarıyla eşleşmiyor.'");
		Common.MessageToUser(Text,ThisObject,,,Cancel);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation, CorrespondenceWithIncome);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ARAPAdjustmentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	ArticlesWithoutSplitting = AdditionalProperties.Property("ArticlesWithoutSplitting") And AdditionalProperties.ArticlesWithoutSplitting;
	If ArticlesWithoutSplitting Then
		CheckContentOfArticles(
			ThisObject, CheckedAttributes, "IncomeExpensesAssetsLiabilities", AdditionalProperties.ArticleElements, Cancel);
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	If WriteMode = DocumentWriteMode.Posting Then		
		
		If IncomeExpensesAssetsLiabilities.Count() = 1 And Debt_.Count() > 0 Then
			IncomeExpensesAssetsLiabilities[0].Currency = Debt_[0].ARAPCurrency;
			IncomeExpensesAssetsLiabilities[0].Sum = Debt_.Total("Sum");
		EndIf;
		
		If Debt_.Count() = 1 And IncomeExpensesAssetsLiabilities.Count() > 1 Then
			Debt_[0].ARAPCurrency = IncomeExpensesAssetsLiabilities[0].Currency;
			Debt_[0].Sum = IncomeExpensesAssetsLiabilities.Total("Sum");
		EndIf;
		
		// Filling in the currency of mutual settlements if the "Use as Currency" option is disabled
		If Not GetFunctionalOption("UseMultipleCurrencies") Then
			ARAPCurrency = Constants.ManagementAccountingCurrency.Get();
			For Each TSRow In Debt_ Do
				If Not ValueIsFilled(TSRow.ARAPCurrency) Then
					TSRow.ARAPCurrency = ARAPCurrency;
				EndIf;
			EndDo;
			For Each TSRow In IncomeExpensesAssetsLiabilities Do
				If Not ValueIsFilled(TSRow.Currency) Then
					TSRow.Currency = ARAPCurrency;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ARAPAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation, CorrespondenceWithIncome);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	//Setting up accounting accounts
	SetupParameters = Documents.ARAPAdjustment.AccountingAccountSettings_(BusinessOperation);
	GLAccountSettingsServer.BeforeWrite(ThisObject, SetupParameters);
	If Debt_.Count() > 0 Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "Debt_");	
	EndIf;
	
	If IncomeExpensesAssetsLiabilities.Count() > 0 Then
		TMCommonUse.FillInDocumentIDs(ThisObject, "IncomeExpensesAssetsLiabilities");
	EndIf;
	
	ARAPAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If ThisIsAccrual Then
		For Each TSRow In Debt_ Do
			If Not ValueIsFilled(TSRow.PaymentDate)
				And (BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable
					And TSRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
					Or BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable
					And TSRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting) Then
				TSRow.PaymentDate = Date;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	ARAPAdjustmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	ARAPAdjustmentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ARAPAdjustmentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInOnBasisOfActOfDiscrepancies(FillingData)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	&BasisOfAct AS Basis,
	|	DiscrepancyReportFollowingReceipt.Ref AS DiscrepancyReportBaseDocument,
	|	DiscrepancyReportFollowingReceipt.Currency AS Currency,
	|	DiscrepancyReportFollowingReceipt.Partner AS Partner,
	|	DiscrepancyReportFollowingReceipt.Counterparty AS Counterparty
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum), 0) AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &BasisOfAct
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum > 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.ThirdPartyIsGuilty
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ARAPObjects.Ref AS Ref
	|FROM
	|	Catalog.Complaints AS Complaints
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (Complaints.Ref = (CAST(ARAPObjects.Object AS Catalog.Complaints)))
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	Complaints.Basis = &BasisOfAct
	|	AND NOT Complaints.DeletionMark";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("BasisOfAct", FillingData.BasisOfAct);
	
	Result = Query.ExecuteBatch();
	HeaderSelection = Result[0].Select();
	
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	Else
		Return;
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.ARWriteOff;
	
	AmountSelection = Result[1].Select();
	ClaimSelection = Result[2].Select();
	If AmountSelection.Next() Then
		If AmountSelection.Sum > 0 Then
			NewRow = Debt_.Add();
			NewRow.ARAPCurrency = HeaderSelection.Currency;
			NewRow.Sum = AmountSelection.Sum;
			NewRow.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
			NewRow.Partner = HeaderSelection.Partner;
			If ClaimSelection.Next() Then 
				NewRow.ARAPObject = ClaimSelection.Ref;
				ThisIsAccrual = True;    
				Counterparty = HeaderSelection.Counterparty;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInBasedOnClaim(FillingData)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	Claim.Organization				AS Organization,
	|	Claim.Counterparty				AS Counterparty,
	|	Claim.Partner					AS Partner,
	|	TRUE								AS ThisIsAccrual,
	|	Claim.ThisIsClaimToVendor	AS CorrespondenceWithIncome,
	|	CASE
	|		WHEN Claim.ThisIsClaimToVendor
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|	END 								AS PaymentType_,
	|	CASE
	|		WHEN Claim.ThisIsClaimToVendor
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfAccountsReceivable)
	|		ELSE VALUE(Enum.BusinessTransactions.AccrualOfAccountsPayable)
	|	END 								AS BusinessOperation,
	|	Claim.GuiltyBusinessUnit		AS Department,
	|	Claim.ARAPObject			AS ARAPObject,
	|	Claim.Currency					AS ARAPCurrency,
	|	Claim.Sum						AS Sum
	|FROM
	|	Catalog.Complaints AS Claim
	|WHERE
	|	Claim.Ref = &Claim
	|";
	
	Query.SetParameter("Claim", FillingData.Claim);
	
	Result = Query.Execute();
	HeaderSelection = Result.Select();
	
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	Else
		Return;
	EndIf;
	
	
	NewRow = Debt_.Add();
	FillPropertyValues(NewRow, HeaderSelection);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillByStructure(FillingData)
	
	If FillingData.Property("BusinessOperation") Then
		BusinessOperation = FillingData.BusinessOperation;
		ThisIsAccrual = BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsReceivable
			Or BusinessOperation = Enums.BusinessTransactions.AccrualOfAccountsPayable;
		CorrespondenceWithIncome = BusinessOperation = Enums.BusinessTransactions.APWriteOff;
	EndIf;
	
EndProcedure

#EndRegion

Procedure CheckContentOfArticles(DocumentObject, CheckedAttributes, TSName, Presentations, Cancel) Export
	
	If Not DocumentObject[TSName].Count() Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	TabularSections = DocumentObject.Metadata().TabularSections;
	FirstPartOfDocument = TabularSections[TSName];
	
	ErrorTemplate = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Поле ""%1"" не заполнено';
						|en = '""%1"" is required'; fa = '""%1"" is required';
						|it = 'Il campo ""%1"" non è compilato';
						|pl = 'Pole ""%1"" nie jest wypełnione';
						|tr = '""%1"" alanı doldurulmadı.'");
	
	For Each AttributeToCheck In CheckedAttributes Do
		
		If StrFind(AttributeToCheck, TSName) = 0 Then
			Continue;
		EndIf;
		
		PosPoints = StrFind(AttributeToCheck, ".");
		If PosPoints = 0 Then
			Continue;
		EndIf;
		
		AttributeName = Mid(AttributeToCheck, PosPoints + 1);
		TagName = FirstPartOfDocument.Attributes[AttributeName].Synonym;
		If Presentations.Property(AttributeName) Then
			TagName = Presentations[AttributeName];
		EndIf;
		
		If Not ValueIsFilled(DocumentObject[TSName][0][AttributeName]) Then
			
			CommonClientServer.MessageToUser(
				StrTemplate(ErrorTemplate, TagName),
				,
				"Items." + Presentations.TSItem + ".CurrentData." + AttributeName,
				,
				Cancel);
		EndIf;
		
		NotCheckedAttributeArray.Add(AttributeToCheck);
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);

EndProcedure

Function BalanceOfDebtOnSettlementObject(FillingData)
	
	ARAPObjects = ARAPObjectsServer.ObjectOfCalculationsFromLink(FillingData);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Balance.PaymentType_ AS PaymentType_,
	|	Balance.Partner AS Partner,
	|	Balance.ARAPObject AS ARAPObject,
	|	Balance.Currency AS ARAPCurrency,
	|	SUM(Balance.Sum) AS Sum
	|FROM
	|	(SELECT
	|		ARAPObjects.PaymentType_ AS PaymentType_,
	|		ARAPObjects.Partner AS Partner,
	|		ARAPObjects.Ref AS ARAPObject,
	|		ARAPObjects.Currency AS Currency,
	|		0 AS Sum
	|	FROM
	|		Catalog.ARAPObjects AS ARAPObjects
	|	WHERE
	|		ARAPObjects.Ref IN(&ARAPObject)
	|
	|	UNION ALL
	|
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		PartnersARAPAccountingBalance.AccountingDimensionByPartners.Partner AS Partner,
	|		PartnersARAPAccountingBalance.ARAPObject AS ARAPObject,
	|		PartnersARAPAccountingBalance.Currency AS ARAPCurrency,
	|		-PartnersARAPAccountingBalance.SumBalance AS Sum
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting.Balance AS PartnersARAPAccountingBalance
	|	WHERE
	|		PartnersARAPAccountingBalance.ARAPObject IN(&ARAPObject)
	|) AS Balance
	|
	|GROUP BY
	|	Balance.PaymentType_,
	|	Balance.Partner,
	|	Balance.ARAPObject,
	|	Balance.Currency";
	
	Query.SetParameter("ARAPObject", ARAPObjects);
	
	Balance = Query.Execute().Unload();
	
	Return Balance;
	
EndFunction
#EndRegion

#EndIf
