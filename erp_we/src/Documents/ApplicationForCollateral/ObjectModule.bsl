
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	InitializeDocument();
	Goods.Add(); // To be able to edit in a simplified interface.
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Date = CurrentSessionDate();
	Protocol.Clear();
	Status = Enums.ProvisionRequestStatuses.Draft;
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
		
	OnePosition = False; // For software processing, we consider that there is always a table so that there is a binding to the object.
	If AdditionalProperties.Property("OnePosition") Then
		OnePosition = AdditionalProperties.OnePosition;
	EndIf;
	
	UseBDRLimits = False; // The default value for UT.
	UseBDRLimits = GetFunctionalOption("UseIEBLimitsOnConsumption")
		Or GetFunctionalOption("UseIEBLimitsOnPurchases") And SuppliedByPurchase;
	ApplicationHasBeenApproved = Enums.ProvisionRequestStatuses.AgreedUpon(Status);
	
	NamesOfPurchaseDetails = Documents.ApplicationForCollateral.NamesOfPurchaseDetails();
	NamesOfDetailsOfLimitingAnalyst = Documents.ApplicationForCollateral.NamesOfDetailsOfLimitingAnalyst();
	NamesOfManualVerificationDetails = New Array;
	
	If UseBDRLimits And ApplicationHasBeenApproved Then
		CommonClientServer.SupplementArray(NamesOfManualVerificationDetails, NamesOfDetailsOfLimitingAnalyst);
	Else
		CommonClientServer.SupplementArray(AttributesNotToCheck, NamesOfDetailsOfLimitingAnalyst);
	EndIf;
	
	If Documents.ApplicationForCollateral.CheckPurchaseAttributes(ThisObject) Then
		CommonClientServer.SupplementArray(NamesOfManualVerificationDetails, NamesOfPurchaseDetails);
	Else
		CommonClientServer.SupplementArray(AttributesNotToCheck, NamesOfPurchaseDetails);
	EndIf;
	
	If OnePosition Then
		
		NamesOfManualVerificationDetails.Add("Goods.ProductsAsAString");
		
		CheckFillingInAttributesOfSinglePosition(
			NamesOfManualVerificationDetails,
			PresentationOfItemAttributes(),
			AttributesNotToCheck,
			Cancel);
		
	EndIf;
	
	If Not ApplicationHasBeenApproved Then
		CommonClientServer.SupplementArray(AttributesNotToCheck, Documents.ApplicationForCollateral.NamesOfHeaderDetails());
	EndIf;
	
	ParametersForCheckingFillingQuantity = ProductsServer.ParametersForCheckingFillingQuantity();
	ParametersForCheckingFillingQuantity.ThisIsCheckOfCurrentLine = OnePosition;
	ProductsServer.CheckQuantityFilling(
		ThisObject,
		CheckedAttributes,
		Cancel,
		ParametersForCheckingFillingQuantity);
	
	ParametersForCheckingWhetherCharacteristicsAreFilledIn = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	ParametersForCheckingWhetherCharacteristicsAreFilledIn.ThisIsCheckOfCurrentLine = OnePosition;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		AttributesNotToCheck,
		Cancel,
		ParametersForCheckingWhetherCharacteristicsAreFilledIn);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForCollateral.ItemsAndDimensionsSelectionParameters(SuppliedByPurchase);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	LimitsByBudgetingDataServer.CheckRelevanceOfRulesForLimitsOnBudgetItems(ThisObject, Cancel);
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AdjustableRecordingMode = Documents.ApplicationForCollateral.WriteMode(ThisObject);
	If AdjustableRecordingMode = DocumentWriteMode.Posting
		And AdjustableRecordingMode <> WriteMode
		And Not AdditionalProperties.Property("SkipFillCheck") 
		And Not CheckFilling() Then
		Cancel = True;
		Return;
	EndIf;
	
	WriteMode = AdjustableRecordingMode;
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	OperationsWithDocumentProtocol.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	ClearPurchaseAttributes();
	
	DocumentAmount = Goods.Total("Sum");
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
	If Not ValueIsFilled(Performer) Then
		Performer = Author;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(Author, Department);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	DisplayPurchaseAttributes = Documents.ApplicationForCollateral.DisplayPurchaseAttributes(ThisObject);
	
	If Not ValueIsFilled(Currency)
		And DisplayPurchaseAttributes Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(Currency)
		And DisplayPurchaseAttributes Then
		// Repeated attempt to fill in the currency if the company is not filled in.
		Currency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
EndProcedure

#EndRegion

#Region SupplyOfProcurement

Procedure ClearPurchaseAttributes()
	
	If Documents.ApplicationForCollateral.DisplayPurchaseAttributes(ThisObject) Then
		Return;
	EndIf;
	
	HeaderData_ = New Structure;
	RowData = New Structure;
	
	For Each OriginalAttributeName In Documents.ApplicationForCollateral.NamesOfPurchaseDetails() Do
		
		AttributeName = StrReplace(OriginalAttributeName, "Goods.", "");
		
		If AttributeName = OriginalAttributeName Then
			HeaderData_.Insert(AttributeName);
		Else
			RowData.Insert(AttributeName);
		EndIf;
		
	EndDo;
	
	FillPropertyValues(ThisObject, HeaderData_);
	For Each RowOfProduct In Goods Do
		FillPropertyValues(RowOfProduct, RowData);
	EndDo;
	
EndProcedure

#EndRegion

#Region OnePosition

Function PresentationOfItemAttributes()
	
	ReturnValue = New Structure;
	
	Attributes = Ref.Metadata().TabularSections.Goods.Attributes;
	For Each Attribute In Attributes Do
		
		AttributeRepresentation = Attribute.Presentation();
		ReturnValue.Insert(Attribute.Name, AttributeRepresentation);
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

Procedure CheckFillingInAttributesOfSinglePosition(AttributesNames, DetailsPresentations, AttributesNotToCheck, Cancel)
	
	ItemPrefix = "Goods.";
	RowOfGoods = Goods[0]; // Checking for the presence of a string before calling
	For Each AttributeName In AttributesNames Do
		
		TableAttributeName = StrReplace(AttributeName, ItemPrefix, "");
		
		If TableAttributeName = AttributeName Then
			Continue;
		EndIf;
		
		AttributesNotToCheck.Add(AttributeName);
		
		If Not ValueIsFilled(RowOfGoods[TableAttributeName]) Then
			
			ErrorText = CommonClientServer.FillingErrorText(
				"Field",
				"FillType",
				DetailsPresentations[TableAttributeName]);
				
			PathToItem = TMCommonUseClientServer.PathToElementOfCurrentRowOfFormTable(
				"Goods",
				TableAttributeName);
				
			Common.MessageToUser(
				ErrorText,
				,// When an error is displayed, an object cannot be specified in the "element".
				PathToItem,,
				Cancel);
				
		EndIf;
			
	EndDo;
	
EndProcedure
#EndRegion

#EndRegion

#EndIf