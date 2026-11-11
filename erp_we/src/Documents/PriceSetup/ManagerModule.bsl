#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("PricesAndDiscounts");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	Structure - Holding tables
//	A list of values is a list of values containing the query texts and their names.
//						It is returned if the 'Get Request Text' property of the Dopparameters parameter
//						has the value True.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PriceSetup") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		Query.SetParameter("Ref", DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableItemsPrices(Query, QueryTexts, Registers);
		QueryTextTableItemsPrices2_5(Query, QueryTexts, Registers);
	EndIf;
	
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure


// Adds the command to create the document "setting item prices".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	FormCommand, Undefined -
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PriceSetup) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PriceSetup.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PriceSetup);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.ResultsOfProductsPriceApproval.AddDocumentReportCommand(ReportsCommands);
	
EndProcedure

// Writes the data in the document setup item cost
// 
// Parameters:
// 	Form - ClientApplicationForm, Structure - A form or generated structure with parameters for writing documents
// 	Comment - String - Comment for writing to the document
// 	PriceApplicationOption - Number - The application of prices (a record or recording and conducting)
// Returns:
// 	Array, Undefined - Array of recorded documents
Function RecordPriceChangesOnServer(Form, Comment = "", PriceApplicationOption = 0) Export
	
	DetailsOfNewDocuments = New Structure;
	DetailsOfNewDocuments.Insert("EmployeeResponsible", Users.CurrentUser());
	DetailsOfNewDocuments.Insert("Comment", Comment);
	DetailsOfNewDocuments.Insert("Status", Enums.ProductPricingStatuses.NotApproved);
	DetailsOfNewDocuments.Insert("Date", Form.Date);
	
	If TMCommonUseClientServer.HasObjectAttribute(Form,"SetTemporaryPrices") Then
		SetTemporaryPrices = Form.SetTemporaryPrices;
		CurrentPriceRefundDate = BegOfDay(Form.EndDateOfThePricePeriod + 86400);
		DetailsOfNewDocuments.Insert("SetTemporaryPrices", SetTemporaryPrices);
		DetailsOfNewDocuments.Insert("EndDateOfThePricePeriod", Form.EndDateOfThePricePeriod);
		SavedPeriodicPriceDocuments = Form.SavedPeriodicPriceDocuments;
	Else
		SetTemporaryPrices = Undefined;
	EndIf; 
	
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Data = New Structure;
	Data.Insert("Form",                    Form);
	Data.Insert("Documents",                New Array);
	Data.Insert("SaveBasic",         False);
	Data.Insert("DetailsOfNewDocuments", DetailsOfNewDocuments);
	Data.Insert("OnlyChangedItems",         True);
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "SavedDocuments") Then
		SavedDocuments = Form.SavedDocuments;//ValueTable
		For Each TSRow In SavedDocuments Do
			DocumentObject = TSRow.Ref.GetObject();
			Data.Documents.Add(DocumentObject);
		EndDo;
	EndIf;
	
	SettingPricesServer.PutPricesInTablePart(Data);
	
	ArrayDocuments = New Array;
	
	BeginTransaction();
	Try
		For Each DocumentObject In Data.Documents Do
			TabularPartProducts = ?(UsePriceManagementSystem25, DocumentObject.Goods2_5, DocumentObject.Goods);
			If TabularPartProducts.Count() > 0 Then
				
				RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(
					Form.Date, DocumentObject.Ref);
				DocumentObject.Date = SettingPricesClientServer.CalculateDocumentDate(
					Form.Date, RoomWithinADay);
				
				Status = Undefined;
				If Not GetFunctionalOption("UseApprovalOfItemPrices")
					Or UserRightsCached.PriceSetupWithoutApproval() Then
					Status = Enums.ProductPricingStatuses.Approved;
				Else
					Status = Enums.ProductPricingStatuses.NotApproved;
				EndIf;
				
				DocumentObject.Status = Status;
				
				If TMCommonUseClientServer.HasObjectAttribute(Form,"SetTemporaryPrices") Then
					DocumentObject.MarketingActivity = ?(Form.SetTemporaryPrices,Form.MarketingActivity,Undefined);
				EndIf;
				
				DocumentObject.Write(?(PriceApplicationOption = 0, DocumentWriteMode.Write,
					DocumentWriteMode.Posting), DocumentPostingMode.Regular);
				
				PriceApproval = Undefined;
				If PriceApplicationOption = 1
					And DocumentObject.Status = Enums.ProductPricingStatuses.NotApproved Then
					CoordinationOfPricesForItemProducts = BusinessProcesses.PriceApproval.CreateBusinessProcess();
					CoordinationOfPricesForItemProducts.Date = CurrentSessionDate();
					CoordinationOfPricesForItemProducts.Fill(DocumentObject.Ref);
					CoordinationOfPricesForItemProducts.Write();
					CoordinationOfPricesForItemProducts.Start(BusinessProcesses.PriceApproval.RoutePoints.Start);
					PriceApproval = CoordinationOfPricesForItemProducts.Ref;
				EndIf;
				
				StructureOfDocuments = New Structure;
				StructureOfDocuments.Insert("PriceSetup", DocumentObject.Ref);
				StructureOfDocuments.Insert("PriceApproval", PriceApproval);
				ArrayDocuments.Add(StructureOfDocuments);
				
			Else
				ThisIsPeriodEndingDocument = False;
				If TypeOf(SetTemporaryPrices) = Type("Boolean") Then
					Filter = New Structure("PriceExpirationDocument",DocumentObject.Ref);
					ThisIsPeriodEndingDocument = SavedPeriodicPriceDocuments.FindRows(Filter).Count() > 0;
				EndIf; 
				
				If ValueIsFilled(DocumentObject.Ref)
					And Not ThisIsPeriodEndingDocument
					Then
					DocumentObject.Read();
					DocumentObject.Delete();
				EndIf;
				
			EndIf;
		EndDo;
		
		If TypeOf(SetTemporaryPrices) = Type("Boolean") Then
			PricePeriodProcessingTable = GetPeriodProcessingTable(
				SetTemporaryPrices,ArrayDocuments,SavedPeriodicPriceDocuments);
			NewPairsOfPeriodicPriceDocuments = SavedPeriodicPriceDocuments.Unload();
			NewPairsOfPeriodicPriceDocuments.Clear();
			For Each SpecificationRow In PricePeriodProcessingTable Do
				If SpecificationRow.DeleteTuple Then
					
					If SpecificationRow.ThereAreMatchingPriceTypes Then
					
						If ValueIsFilled(SpecificationRow.DocumentOfBeginningOfPeriodOfValidityOfPrices) Then
							DocumentToDelete_ = SpecificationRow.DocumentOfBeginningOfPeriodOfValidityOfPrices.GetObject();//DocumentObject
							If DocumentToDelete_ <> Undefined Then
								DocumentToDelete_.Delete();
							EndIf; 
						EndIf; 
						If ValueIsFilled(SpecificationRow.PriceExpirationDocument) Then
							DocumentToDelete_ = SpecificationRow.PriceExpirationDocument.GetObject();//DocumentObject
							If DocumentToDelete_ <> Undefined Then
								DocumentToDelete_.Delete();
							EndIf; 
						EndIf; 
						
					EndIf;
					
				ElsIf SetTemporaryPrices Then
					If SpecificationRow.PeriodEndDocumentExists Then
						PricePeriodCompletionDocument = SpecificationRow.PriceExpirationDocument.GetObject();
					Else
						PricePeriodCompletionDocument = Documents.PriceSetup.CreateDocument();
					EndIf;
					If UsePriceManagementSystem25 Then
						FillOutDocumentOfEndOfPromotion25(PricePeriodCompletionDocument,
															SpecificationRow.DocumentOfTheBeginningOfThePriceValidityPeriod, 
															CurrentPriceRefundDate);
					Else
						FillOutDocumentOfEndOfPromotion(PricePeriodCompletionDocument,
															SpecificationRow.DocumentOfTheBeginningOfThePriceValidityPeriod, 
															CurrentPriceRefundDate);
					EndIf;
					RoomWithinADay = PriceSetupServerCall.CalculateNumberWithinDay(
															CurrentPriceRefundDate, 
															PricePeriodCompletionDocument.Ref);
					PricePeriodCompletionDocument.Date = SettingPricesClientServer.CalculateDocumentDate(
															CurrentPriceRefundDate, 
															RoomWithinADay);
					PricePeriodCompletionDocument.Write(
						?(PriceApplicationOption = 0, DocumentWriteMode.Write, DocumentWriteMode.Posting), 
						DocumentPostingMode.Regular);
					
					StructureOfDocuments = New Structure;
					StructureOfDocuments.Insert("PriceSetup", PricePeriodCompletionDocument.Ref);
					StructureOfDocuments.Insert("PriceApproval", PriceApproval);
					StructureOfDocuments.Insert("DocumentOfTheBeginningOfThePriceValidityPeriod", SpecificationRow.DocumentOfTheBeginningOfThePriceValidityPeriod);
					ArrayDocuments.Add(StructureOfDocuments);
					
					PairString = NewPairsOfPeriodicPriceDocuments.Add();
					PairString.DocumentOfTheBeginningOfThePriceValidityPeriod = SpecificationRow.DocumentOfTheBeginningOfThePriceValidityPeriod;
					PairString.PriceExpirationDocument = PricePeriodCompletionDocument.Ref;
				Else
					If SpecificationRow.PeriodEndDocumentExists Then
						DocumentToDelete_ = SpecificationRow.PriceExpirationDocument.GetObject();//DocumentObject
						If DocumentToDelete_ <> Undefined Then
							DocumentToDelete_.Delete();
						EndIf; 
					EndIf;
				EndIf; 
			EndDo; 
		EndIf;
		
		CommitTransaction();
		
		If TypeOf(SetTemporaryPrices) = Type("Boolean") Then
			SavedPeriodicPriceDocuments.Clear();
			SavedPeriodicPriceDocuments.Load(NewPairsOfPeriodicPriceDocuments);
		EndIf;
		
	Except
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Lỗi khi đặt bảng giá. Nguyên nhân: %Cause%';
							|ru = 'Ошибка при установке цен. Причина: %Cause%';
							|en = 'An error occurred when setting the price. Reason: %Cause%'; fa = 'An error occurred when setting the price. Reason: %Cause%';
							|it = 'Errore durante l''impostazione dei prezzi. Causa: %Cause%';
							|pl = 'Błąd podczas ustawienia cen. Przyczyna: %Cause%';
							|tr = 'Fiyatlar yapılandırılırken hata oluştu. Neden: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(MessageText); 

		WriteLogEvent(
			NStr("vi = 'Lỗi thực hiện';
				|ru = 'Ошибка выполнения';
				|en = 'Runtime error'; fa = 'خطای زمان اجرا';
				|it = 'Errore nell''esecuzione';
				|pl = 'Błąd wykonania';
				|tr = 'Uygulama hatası'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.DataProcessors.PriceList,
			,
			DetailErrorDescription(ErrorInfo()));

	EndTry;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "SavedDocuments") Then
		SavedDocuments = Form.SavedDocuments;//ValueTable
		
		SettingPricesServer.ClearSavedDocuments(SavedDocuments, Form.UUID);
		
		For Each TSRow In ArrayDocuments Do
			NewRow = SavedDocuments.Add();
			NewRow.Ref = TSRow.PriceSetup;
			LockDataForEdit(TSRow.PriceSetup,,Form.UUID);
		EndDo;
	EndIf;
	
	Form.Modified = False;
	
	Return ArrayDocuments;
	
EndFunction

// Parameters:
//	SetTemporaryPrices - Boolean
//	ArrayDocuments - Array of DocumentRef.PriceSetup
//	SavedPeriodicPriceDocuments - ValueTable
// Returns:
//	ValueTable
Function GetPeriodProcessingTable(SetTemporaryPrices,ArrayDocuments,SavedPeriodicPriceDocuments)
	
	RecordedDocuments = New ValueTable;
	RecordedDocuments.Columns.Add("Ref",New TypeDescription("DocumentRef.PriceSetup"));
	For Each Item In ArrayDocuments Do
		TableRow = RecordedDocuments.Add();
		TableRow.Ref = Item.PriceSetup;
	EndDo; 
	
	QueryText = 
	"SELECT
	|	PriceSetup.Ref AS Ref
	|INTO CurDocumentsOfBeginningOfPeriod
	|FROM
	|	&RecordedDocuments AS PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SavedPairsOfPeriodDocuments.DocumentOfTheBeginningOfThePriceValidityPeriod AS DocumentOfTheBeginningOfThePriceValidityPeriod,
	|	SavedPairsOfPeriodDocuments.PriceExpirationDocument AS PriceExpirationDocument
	|INTO SavedPairsOfPeriodDocuments
	|FROM
	|	&DocumentsOfValidityPeriods AS SavedPairsOfPeriodDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SavedPairsOfPeriodDocuments.DocumentOfTheBeginningOfThePriceValidityPeriod AS DocumentOfTheBeginningOfThePriceValidityPeriod,
	|	CASE
	|		WHEN CurDocumentsOfBeginningOfPeriod.Ref IS NULL
	|			THEN SavedPairsOfPeriodDocuments.PriceExpirationDocument
	|		ELSE VALUE(Document.PriceSetup.EmptyRef)
	|	END AS PriceExpirationDocument
	|INTO SavedPairsOfPeriodDocumentsNormalized
	|FROM
	|	SavedPairsOfPeriodDocuments AS SavedPairsOfPeriodDocuments
	|		LEFT JOIN CurDocumentsOfBeginningOfPeriod AS CurDocumentsOfBeginningOfPeriod
	|		ON SavedPairsOfPeriodDocuments.PriceExpirationDocument = CurDocumentsOfBeginningOfPeriod.Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfPriceTypes.PriceKind AS PriceKind
	|INTO PriceTypesOfNewDocuments
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS TableOfPriceTypes
	|WHERE
	|	TableOfPriceTypes.Ref IN
	|		(SELECT
	|			CurDocumentsOfBeginningOfPeriod.Ref
	|		FROM
	|			CurDocumentsOfBeginningOfPeriod)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfPriceTypes.PriceKind AS PriceKind
	|INTO PriceTypesOfOldDocuments
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS TableOfPriceTypes
	|WHERE
	|	TableOfPriceTypes.Ref IN
	|		(SELECT
	|			SavedPairsOfPeriodDocuments.DocumentOfTheBeginningOfThePriceValidityPeriod
	|		FROM
	|			SavedPairsOfPeriodDocuments)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE AS PriceTypeMatches
	|INTO ThereAreMatchingPriceTypes
	|FROM
	|	PriceTypesOfNewDocuments AS PriceTypesOfNewDocuments
	|		INNER JOIN PriceTypesOfOldDocuments AS PriceTypesOfOldDocuments
	|		ON PriceTypesOfNewDocuments.PriceKind = PriceTypesOfOldDocuments.PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurDocumentsOfBeginningOfPeriod.Ref AS DocumentOfTheBeginningOfThePriceValidityPeriod,
	|	SavedPairsOfPeriodDocuments.PriceExpirationDocument AS PriceExpirationDocument,
	|	SavedPairsOfPeriodDocuments.DocumentOfTheBeginningOfThePriceValidityPeriod AS DocumentOfBeginningOfPeriodOfValidityOfPrices,
	|	CASE
	|		WHEN CurDocumentsOfBeginningOfPeriod.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS DeleteTuple,
	|	TRUE IN
	|		(SELECT
	|			ThereAreMatchingPriceTypes.PriceTypeMatches
	|		FROM
	|			ThereAreMatchingPriceTypes) AS ThereAreMatchingPriceTypes,
	|	CASE
	|		WHEN SavedPairsOfPeriodDocuments.PriceExpirationDocument IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS PeriodEndDocumentExists
	|FROM
	|	CurDocumentsOfBeginningOfPeriod AS CurDocumentsOfBeginningOfPeriod
	|		FULL JOIN SavedPairsOfPeriodDocumentsNormalized AS SavedPairsOfPeriodDocuments
	|		ON CurDocumentsOfBeginningOfPeriod.Ref = SavedPairsOfPeriodDocuments.DocumentOfTheBeginningOfThePriceValidityPeriod";
	
	Query = New Query(QueryText);
	Query.SetParameter("RecordedDocuments",RecordedDocuments);
	Query.SetParameter("DocumentsOfValidityPeriods",SavedPeriodicPriceDocuments.Unload());
	
	Return Query.Execute().Unload();
	
EndFunction // Get the Processing Period table()
 
Function FillOutDocumentOfEndOfPromotion(DocumentObject,Val ActionStartDocument, Val RefundDate_)
	
	TexDataRequestDocumentCompletionPromotion = 
	"SELECT
	|	&DocumentDate AS Date,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsible,
	|	PriceSetup.Comment AS Comment,
	|	PriceSetup.Approved AS Approved,
	|	PriceSetup.Status AS Status
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &ActionStartDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PriceSetupTypesOfPrices.PriceKind AS PriceKind,
	|	PriceSetupTypesOfPrices.DataCompositionSettings AS DataCompositionSettings
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS PriceSetupTypesOfPrices
	|WHERE
	|	PriceSetupTypesOfPrices.Ref = &ActionStartDocument
	|
	|ORDER BY
	|	PriceSetupTypesOfPrices.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|	SettingPricesForProductProductRange.Package AS Package,
	|	SettingPricesForProductProductRange.PriceKind AS PriceKind,
	|	SettingPricesForProductProductRange.Price AS Price,
	|	SettingPricesForProductProductRange.Currency AS Currency
	|INTO ProductsPromotions
	|FROM
	|	Document.PriceSetup.Goods AS SettingPricesForProductProductRange
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &ActionStartDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsPromotions.Products AS Products,
	|	ProductsPromotions.Characteristic AS Characteristic,
	|	ProductsPromotions.Package AS Package,
	|	ProductsPromotions.PriceKind AS PriceKind,
	|	ProductsPromotions.Price AS SharePrice,
	|	FALSE AS PriceIsChangedManually,
	|	ProductsPromotions.Currency AS Currency,
	|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
	|	ItemPricesCrossSectionOfTheLatest.Formula AS Formula
	|FROM
	|	ProductsPromotions AS ProductsPromotions
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				&BeforePromotion,
	|				(Products, Characteristic, PriceKind) IN
	|					(SELECT
	|						ProductsPromotions.Products,
	|						ProductsPromotions.Characteristic,
	|						ProductsPromotions.PriceKind
	|					FROM
	|						ProductsPromotions AS ProductsPromotions)) AS ItemPricesCrossSectionOfTheLatest
	|		ON ProductsPromotions.Products = ItemPricesCrossSectionOfTheLatest.Products
	|			AND ProductsPromotions.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|			AND ProductsPromotions.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|			AND ProductsPromotions.Package = ItemPricesCrossSectionOfTheLatest.Package
	|			AND ProductsPromotions.Currency = ItemPricesCrossSectionOfTheLatest.Currency
	|
	|ORDER BY
	|	ProductsPromotions.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsPromotions";
	
	Query = New Query(TexDataRequestDocumentCompletionPromotion);
	Query.SetParameter("ActionStartDocument",ActionStartDocument);
	Query.SetParameter("DocumentDate",RefundDate_);
	Query.SetParameter("BeforePromotion",
		BegOfDay(Common.ObjectAttributeValue(ActionStartDocument,"Date"))-1);
	Results = Query.ExecuteBatch();
	
	DocumentObject = Documents.PriceSetup.CreateDocument();
	
	SampleBankingDetails = Results[0].Select();
	SampleBankingDetails.Next();
	FillPropertyValues(DocumentObject,SampleBankingDetails);
	
	DocumentObject.TypesOfPrices.Clear();
	SamplingTypesOfPrices = Results[1].Select();
	While SamplingTypesOfPrices.Next() Do
		PriceString = DocumentObject.TypesOfPrices.Add();
		FillPropertyValues(PriceString,SamplingTypesOfPrices);
	EndDo; 
	
	DocumentObject.Goods.Clear();
	SampleProducts_ = Results[3].Select();
	While SampleProducts_.Next() Do
		RowGoods = DocumentObject.Goods.Add();
		FillPropertyValues(RowGoods,SampleProducts_);
	EndDo; 
	
	Return DocumentObject;
	
EndFunction

Function FillOutDocumentOfEndOfPromotion25(DocumentObject,Val ActionStartDocument, Val RefundDate_)
	
	TexDataRequestDocumentCompletionPromotion = 
	"SELECT
	|	&DocumentDate AS Date,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsible,
	|	PriceSetup.Comment AS Comment,
	|	PriceSetup.Approved AS Approved,
	|	PriceSetup.Status AS Status
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &ActionStartDocument
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PriceSetupTypesOfPrices.PriceKind AS PriceKind,
	|	PriceSetupTypesOfPrices.DataCompositionSettings AS DataCompositionSettings
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS PriceSetupTypesOfPrices
	|WHERE
	|	PriceSetupTypesOfPrices.Ref = &ActionStartDocument
	|ORDER BY
	|	PriceSetupTypesOfPrices.LineNumber
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|	SettingPricesForProductProductRange.PricingBatch AS PricingBatch,
	|	SettingPricesForProductProductRange.PricingPackage AS PricingPackage,
	|	SettingPricesForProductProductRange.Package AS Package,
	|	SettingPricesForProductProductRange.PriceKind AS PriceKind,
	|	SettingPricesForProductProductRange.Price AS Price,
	|	SettingPricesForProductProductRange.Currency AS Currency
	|INTO ProductsPromotions
	|FROM
	|	Document.PriceSetup.Goods2_5 AS SettingPricesForProductProductRange
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &ActionStartDocument
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsPromotions.Products AS Products,
	|	ProductsPromotions.PricingVariant AS PricingVariant,
	|	ProductsPromotions.PricingBatch AS PricingBatch,
	|	ProductsPromotions.PricingPackage AS PricingPackage,
	|	ProductsPromotions.Package AS Package,
	|	ProductsPromotions.PriceKind AS PriceKind,
	|	ProductsPromotions.Price AS SharePrice,
	|	FALSE AS PriceIsChangedManually,
	|	ProductsPromotions.Currency AS Currency,
	|	ItemPricesCrossSectionOfTheLatest.Price AS Price,
	|	ItemPricesCrossSectionOfTheLatest.Formula AS Formula
	|FROM
	|	ProductsPromotions AS ProductsPromotions
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&BeforePromotion, (Products, PricingVariant,
	|			PricingBatch, PricingPackage, PriceKind) IN
	|			(SELECT
	|				ProductsPromotions.Products,
	|				ProductsPromotions.PricingVariant,
	|				ProductsPromotions.PricingBatch,
	|				ProductsPromotions.PricingPackage,
	|				ProductsPromotions.PriceKind
	|			FROM
	|				ProductsPromotions AS ProductsPromotions)) AS ItemPricesCrossSectionOfTheLatest
	|		ON ProductsPromotions.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND ProductsPromotions.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND ProductsPromotions.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND ProductsPromotions.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND ProductsPromotions.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		AND ProductsPromotions.Package = ItemPricesCrossSectionOfTheLatest.Package
	|		AND ProductsPromotions.Currency = ItemPricesCrossSectionOfTheLatest.Currency
	|ORDER BY
	|	ProductsPromotions.LineNumber
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsPromotions";
	
	Query = New Query(TexDataRequestDocumentCompletionPromotion);
	Query.SetParameter("ActionStartDocument",ActionStartDocument);
	Query.SetParameter("DocumentDate",RefundDate_);
	Query.SetParameter("BeforePromotion",
		BegOfDay(Common.ObjectAttributeValue(ActionStartDocument,"Date"))-1);
	Results = Query.ExecuteBatch();
	
	DocumentObject = Documents.PriceSetup.CreateDocument();
	
	SampleBankingDetails = Results[0].Select();
	SampleBankingDetails.Next();
	FillPropertyValues(DocumentObject,SampleBankingDetails);
	
	DocumentObject.TypesOfPrices.Clear();
	SamplingTypesOfPrices = Results[1].Select();
	While SamplingTypesOfPrices.Next() Do
		PriceString = DocumentObject.TypesOfPrices.Add();
		FillPropertyValues(PriceString,SamplingTypesOfPrices);
	EndDo; 
	
	DocumentObject.Goods2_5.Clear();
	SampleProducts_ = Results[3].Select();
	While SampleProducts_.Next() Do
		RowGoods = DocumentObject.Goods2_5.Add();
		FillPropertyValues(RowGoods,SampleProducts_);
	EndDo; 
	
	Return DocumentObject;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ForAllRows(ValueAllowed(TypesOfPrices.PriceKind, Null AS TRUE))";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function QueryTextTableItemsPrices(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPrices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 


	QueryText =
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Price AS Price,
	|	CASE
	|		WHEN GoodsTable.Currency = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN TypesOfCatPrices.PriceCurrency
	|		ELSE GoodsTable.Currency
	|	END AS Currency,
	|	GoodsTable.Formula AS Formula,
	|	PriceSetup.MarketingActivity AS MarketingActivity,
	|	PriceSetup.Date AS Period
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|		LEFT JOIN Document.PriceSetup.Goods AS GoodsTable
	|		ON PriceSetup.Ref = GoodsTable.Ref
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfCatPrices
	|		ON GoodsTable.PriceKind = TypesOfCatPrices.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON GoodsTable.Products = CatProducts_.Ref
	|WHERE
	|	PriceSetup.Ref = &Ref
	|	AND PriceSetup.Status = VALUE(Enum.ProductPricingStatuses.Approved)
	|	AND
	|		(CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	OR GoodsTable.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef))";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPrices2_5(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPrices25";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	QueryText =
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PricingVariant AS PricingVariant,
	|	CASE
	|		WHEN ItemsBatchesForPricing.Predefined
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE GoodsTable.PricingBatch
	|	END AS PricingBatch,
	|	CASE
	|		WHEN GoodsTable.PricingPackage = CatProducts_.UnitOfMeasure
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE GoodsTable.PricingPackage
	|	END AS PricingPackage,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Price AS Price,
	|	CASE
	|		WHEN GoodsTable.Currency = VALUE(Catalog.Currencies.EmptyRef)
	|			THEN TypesOfCatPrices.PriceCurrency
	|		ELSE GoodsTable.Currency
	|	END AS Currency,
	|	CASE
	|		WHEN (TypesOfCatPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
	|				OR TypesOfCatPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine))
	|			THEN GoodsTable.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate,
	|	GoodsTable.Formula AS Formula,
	|	PriceSetup.MarketingActivity AS MarketingActivity,
	|	PriceSetup.Date AS Period
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|		LEFT JOIN Document.PriceSetup.Goods2_5 AS GoodsTable
	|		ON (PriceSetup.Ref = GoodsTable.Ref)
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfCatPrices
	|		ON (GoodsTable.PriceKind = TypesOfCatPrices.Ref)
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|			LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|			ON (CatProducts_.ProductKind = ItemKinds.Ref)
	|		ON (GoodsTable.Products = CatProducts_.Ref)
	|		LEFT JOIN Catalog.ItemsBatchesForPricing AS ItemsBatchesForPricing
	|		ON (GoodsTable.PricingBatch = ItemsBatchesForPricing.Ref)
	|WHERE
	|	PriceSetup.Status = VALUE(Enum.ProductPricingStatuses.Approved)
	|	AND GoodsTable.Ref = &Ref
	|	AND
	|		(CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	OR
	|		ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|	OR GoodsTable.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If GetFunctionalOption("UseRetailSales") Then
		// Retail revaluation
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintRevaluationInRetail";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "GoodsRevaluationInRetail";
		PrintCommand.Presentation = NStr("vi = 'Đánh giá lại trong bán lẻ';
										|ru = 'Переоценка в рознице';
										|en = 'Revaluation in retail'; fa = 'تجدید ارزیابی در خرده‌فروشی';
										|it = 'Rivalutazione dei prezzi nella vendita al dettaglio';
										|pl = 'Przeszacowanie w handlu detalicznym';
										|tr = 'Perakendede yeniden değerleme'");
	EndIf;

	// Setting item prices
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "PrintManagementTMClient.PrintProductPricing";
	PrintCommand.PrintManager = "";
	PrintCommand.Id = "PriceSetup";
	PrintCommand.Presentation = NStr("vi = 'Đặt bảng giá';
									|ru = 'Установка цен номенклатуры';
									|en = 'Price setup'; fa = 'تنظیم قیمت';
									|it = 'Impostazione dei prezzi degli articoli';
									|pl = 'Ustawianie cen towarów';
									|tr = 'Ürün fiyatlarını belirleme'");

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.PriceSetup";
		PrintCommand.Id = "PriceTags";
		PrintCommand.Presentation = NStr("vi = 'Nhãn giá';
										|ru = 'Ценники';
										|en = 'Price tags'; fa = 'برچسب‌های قیمت';
										|it = 'Cartellini del prezzo';
										|pl = 'Price tags';
										|tr = 'Fiyat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.PriceSetup";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;

EndProcedure

// Procedure for printing a document.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsRevaluationInRetail") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsRevaluationInRetail",
			NStr("vi = 'Đánh giá lại hàng hóa bán lẻ';
				|ru = 'Переоценка товаров в рознице';
				|en = 'Goods revaluation in retail'; fa = 'تجدید ارزیابی کالا در خرده‌فروشی';
				|it = 'Rivalutazione delle merci nella vendita al dettaglio';
				|pl = 'Przeszacowanie towarów w handlu detalicznym';
				|tr = 'Perakende ürünleri yeniden değerleme'"),
			CreatePrintedFormOfRevaluationOfGoodsInRetail(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PriceSetup") Then
			PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PriceSetup",
			NStr("vi = 'Đặt bảng giá';
				|ru = 'Установка цен номенклатуры';
				|en = 'Price setup'; fa = 'تنظیم قیمت';
				|it = 'Impostazione dei prezzi degli articoli';
				|pl = 'Ustawianie cen towarów';
				|tr = 'Ürün fiyatlarını belirleme'"),
			CreatePrintedFormForSettingProductPrices(ObjectsArray, PrintObjects, PrintParameters));
	EndIf;
	
EndProcedure

#Region QueryTexts

Function TextOfRequestForRevaluationOfGoodsInRetailTTByAssortment()
	QueryText = 
	"SELECT
	|	Goods.LineNumber    AS LineNumber,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package       AS Package,
	|	Goods.Price           AS Price,
	|	Goods.PriceKind        AS PriceKind
	|INTO DataTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|SELECT
	|	ProductRange.Products AS Products,
	|	ProductRange.PriceKind AS PriceKind
	|INTO ProductTypesOfPrices
	|FROM
	|	InformationRegister.ProductRange.SliceLast(
	|			ENDOFPERIOD(&DocumentDate, DAY),
	|			PlanningObject = &PlanningObject
	|				AND Products IN
	|					(SELECT
	|						T.Products
	|					FROM
	|						DataTable AS T)) AS ProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.LineNumber                            AS LineNumber,
	|	NestedQuery.Products                           AS Products,
	|	CatalogProducts.Code                             AS Code,
	|	CatalogProducts.SKU                         AS SKU,
	|	CatalogProducts.DescriptionFull              AS FullNameOfProduct_,
	|	CatalogProducts.UnitOfMeasure.Presentation  AS UnitOfMeasure,
	|	NestedQuery.Characteristic                         AS Characteristic,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1                                                      AS ZoomRatio,
	|	NestedQuery.NewRetailPrice                      AS RetailPrice,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) AS CostDeviation,
	|	ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count
	|FROM
	|		(SELECT
	|			SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|			SettingPricesForProductProductRange.Products AS Products,
	|			SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|			SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice,
	|			SettingPricesForProductProductRange.PriceKind AS PriceKind
	|		FROM
	|			DataTable AS SettingPricesForProductProductRange
	|				INNER JOIN ProductTypesOfPrices AS ProductTypesOfPrices
	|				ON ProductTypesOfPrices.Products = SettingPricesForProductProductRange.Products
	|				AND ProductTypesOfPrices.PriceKind = SettingPricesForProductProductRange.PriceKind
	|			) AS NestedQuery
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				ENDOFPERIOD(&PreviousDayEnd, DAY),
	|				(Products, PriceKind) IN
	|					(SELECT
	|						T.Products,
	|						T.PriceKind
	|					FROM
	|						ProductTypesOfPrices AS T
	|					)) AS ItemPricesCrossSectionOfTheLatest
	|		ON (NestedQuery.Products = ItemPricesCrossSectionOfTheLatest.Products)
	|			AND (NestedQuery.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic)
	|			AND (NestedQuery.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind)
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			NestedQuery.Products = Dimension.Products
	|			AND NestedQuery.Characteristic = Dimension.Characteristic
	|			AND &RetailStore = Dimension.StorageLocation
	|		
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(
	|				&PreviousDayEnd,
	|				Organization = &Organization) AS CompanyGoodsBalance
	|		ON (Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes)
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = NestedQuery.Products
	|		
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = NestedQuery.Characteristic
	|WHERE
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|	
	|ORDER BY
	|	NestedQuery.LineNumber
	|";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailTTByAssortment2_5()
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	CAST(Goods.PricingVariant AS Catalog.ItemsCharacteristicsForPricing) AS PricingVariant,
	|	CAST(Goods.PricingBatch AS Catalog.ItemsBatchesForPricing) AS PricingBatch,
	|	CAST(Goods.PricingPackage AS Catalog.PackagesAndUnitsOfMeasure) AS PricingPackage,
	|	Goods.Package AS Package,
	|	Goods.Price AS Price,
	|	Goods.PriceKind AS PriceKind
	|INTO DataTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO ProductsTable
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON DataTable.Products.ProductKind = ItemKinds.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON DataTable.Products = CatProducts_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Products AS Products,
	|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|	DataTable.PricingVariant AS PricingVariant,
	|	DataTable.PricingBatch AS PricingBatch,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	DataTable.PricingPackage AS PricingPackage,
	|	DataTable.Package AS Package,
	|	DataTable.Price AS Price,
	|	DataTable.PriceKind AS PriceKind,
	|	ProductsTable.ByPackage AS ByPackage,
	|	ProductsTable.ByItemVariant AS ByItemVariant,
	|	ProductsTable.ByBatch AS ByBatch
	|INTO ExtendedDataTable
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN ProductsTable AS ProductsTable
	|		ON DataTable.Products = ProductsTable.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON DataTable.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND ProductsTable.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON DataTable.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND DataTable.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON ProductsTable.ByBatch
	|		AND DataTable.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND DataTable.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductRange.Products AS Products,
	|	ProductRange.PriceKind AS PriceKind
	|INTO ProductTypesOfPrices
	|FROM
	|	InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&DocumentDate, DAY),
	|		PlanningObject = &PlanningObject
	|	AND Products IN
	|		(SELECT
	|			T.Products
	|		FROM
	|			ProductsTable AS T)) AS ProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.LineNumber AS LineNumber,
	|	NestedQuery.Products AS Products,
	|	CatalogProducts.Code AS Code,
	|	CatalogProducts.SKU AS SKU,
	|	CatalogProducts.DescriptionFull AS FullNameOfProduct_,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN NestedQuery.PricingPackage.Presentation
	|		ELSE CatalogProducts.UnitOfMeasure.Presentation
	|	END AS UnitOfMeasure,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.PricingVariant AS PricingVariant,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1 AS ZoomRatio,
	|	NestedQuery.NewRetailPrice AS RetailPrice,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|				ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0))
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))
	|	END AS CostDeviation,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)
	|		ELSE ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)
	|	END AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count,
	|	NestedQuery.ByItemVariant AS ByItemVariant,
	|	NestedQuery.ByBatch AS ByBatch,
	|	NestedQuery.ByPackage AS ByPackage
	|FROM
	|	(SELECT
	|		SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|		SettingPricesForProductProductRange.Products AS Products,
	|		SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|		SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|		SettingPricesForProductProductRange.PricingBatch AS PricingBatch,
	|		SettingPricesForProductProductRange.Series AS Series,
	|		SettingPricesForProductProductRange.PricingPackage AS PricingPackage,
	|		CASE
	|			WHEN SettingPricesForProductProductRange.ByPackage
	|				THEN SettingPricesForProductProductRange.Price
	|			ELSE SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1)
	|		END AS NewRetailPrice,
	|		SettingPricesForProductProductRange.PriceKind AS PriceKind,
	|		SettingPricesForProductProductRange.ByItemVariant AS ByItemVariant,
	|		SettingPricesForProductProductRange.ByBatch AS ByBatch,
	|		SettingPricesForProductProductRange.ByPackage AS ByPackage
	|	FROM
	|		ExtendedDataTable AS SettingPricesForProductProductRange
	|			INNER JOIN ProductTypesOfPrices AS ProductTypesOfPrices
	|			ON ProductTypesOfPrices.Products = SettingPricesForProductProductRange.Products
	|			AND ProductTypesOfPrices.PriceKind = SettingPricesForProductProductRange.PriceKind) AS NestedQuery
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&PreviousDayEnd, DAY),
	|			(Products, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PriceKind
	|			FROM
	|				ProductTypesOfPrices AS T)) AS ItemPricesCrossSectionOfTheLatest
	|		ON NestedQuery.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND NestedQuery.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND NestedQuery.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND NestedQuery.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND NestedQuery.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON NestedQuery.Products = Dimension.Products
	|		AND NestedQuery.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS
	|			CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = NestedQuery.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = NestedQuery.Characteristic
	|WHERE
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|				ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)) <> 0
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|	END
	|
	|ORDER BY
	|	NestedQuery.LineNumber";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailTT()
	QueryText =
	"SELECT
	|	Goods.LineNumber    AS LineNumber,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package       AS Package,
	|	Goods.Price           AS Price,
	|	Goods.PriceKind        AS PriceKind
	|INTO DataTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|SELECT
	|	NestedQuery.LineNumber                                 AS LineNumber,
	|	NestedQuery.Products                                AS Products,
	|	CatalogProducts.Code                                  AS Code,
	|	CatalogProducts.SKU                              AS SKU,
	|	CatalogProducts.DescriptionFull                   AS FullNameOfProduct_,
	|	CatalogProducts.UnitOfMeasure.Presentation       AS UnitOfMeasure,
	|	NestedQuery.Characteristic                              AS Characteristic,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull      AS FullNameOfCharacteristic,
	|	1                                                           AS ZoomRatio,
	|	NestedQuery.NewRetailPrice                           AS RetailPrice,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice - (ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))) AS CostDeviation,
	|	ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count
	|FROM
	|	(SELECT
	|			SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|			SettingPricesForProductProductRange.Products AS Products,
	|			SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|			SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice
	|		FROM
	|			DataTable AS SettingPricesForProductProductRange
	|		WHERE
	|			SettingPricesForProductProductRange.PriceKind = &PriceKind
	|	) AS NestedQuery
	|		
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&PreviousDayEnd, DAY), (Products, Characteristic, PriceKind) IN (SELECT T.Products, T.Characteristic, T.PriceKind FROM DataTable AS T WHERE T.PriceKind = &PriceKind)) AS ItemPricesCrossSectionOfTheLatest
	|		ON NestedQuery.Products = ItemPricesCrossSectionOfTheLatest.Products
	|			AND NestedQuery.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|		
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			NestedQuery.Products = Dimension.Products
	|			AND NestedQuery.Characteristic = Dimension.Characteristic
	|			AND &RetailStore = Dimension.StorageLocation
	|		
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = NestedQuery.Products
	|		
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = NestedQuery.Characteristic
	|WHERE
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice - (ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))) <> 0
	|	
	|ORDER BY
	|	NestedQuery.LineNumber
	|
	|";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailTT2_5()
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	CAST(Goods.PricingVariant AS Catalog.ItemsCharacteristicsForPricing) AS PricingVariant,
	|	CAST(Goods.PricingBatch AS Catalog.ItemsBatchesForPricing) AS PricingBatch,
	|	CAST(Goods.PricingPackage AS Catalog.PackagesAndUnitsOfMeasure) AS PricingPackage,
	|	Goods.Package AS Package,
	|	Goods.Price AS Price,
	|	Goods.PriceKind AS PriceKind
	|INTO DataTable
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataTable.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO ProductsTable
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON DataTable.Products.ProductKind = ItemKinds.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON DataTable.Products = CatProducts_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	DataTable.Products AS Products,
	|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|	DataTable.PricingVariant AS PricingVariant,
	|	DataTable.PricingBatch AS PricingBatch,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	DataTable.PricingPackage AS PricingPackage,
	|	DataTable.Package AS Package,
	|	DataTable.Price AS Price,
	|	DataTable.PriceKind AS PriceKind,
	|	ProductsTable.ByPackage AS ByPackage,
	|	ProductsTable.ByItemVariant AS ByItemVariant,
	|	ProductsTable.ByBatch AS ByBatch
	|INTO ExtendedDataTable
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN ProductsTable AS ProductsTable
	|		ON DataTable.Products = ProductsTable.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON DataTable.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND ProductsTable.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON DataTable.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND DataTable.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON ProductsTable.ByBatch
	|		AND DataTable.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND DataTable.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.LineNumber AS LineNumber,
	|	NestedQuery.Products AS Products,
	|	CatalogProducts.Code AS Code,
	|	CatalogProducts.SKU AS SKU,
	|	CatalogProducts.DescriptionFull AS FullNameOfProduct_,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN NestedQuery.PricingPackage.Presentation
	|		ELSE CatalogProducts.UnitOfMeasure.Presentation
	|	END AS UnitOfMeasure,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.PricingVariant AS PricingVariant,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1 AS ZoomRatio,
	|	NestedQuery.NewRetailPrice AS RetailPrice,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|				ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0))
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))
	|	END AS CostDeviation,
	|	CASE
	|		WHEN NestedQuery.ByPackage
	|			THEN ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)
	|		ELSE ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)
	|	END AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count,
	|	NestedQuery.ByItemVariant AS ByItemVariant,
	|	NestedQuery.ByBatch AS ByBatch,
	|	NestedQuery.ByPackage AS ByPackage
	|FROM
	|	(SELECT
	|		SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|		SettingPricesForProductProductRange.Products AS Products,
	|		SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|		SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|		SettingPricesForProductProductRange.PricingBatch AS PricingBatch,
	|		SettingPricesForProductProductRange.Series AS Series,
	|		SettingPricesForProductProductRange.PricingPackage AS PricingPackage,
	|		CASE
	|			WHEN SettingPricesForProductProductRange.ByPackage
	|				THEN SettingPricesForProductProductRange.Price
	|			ELSE SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1)
	|		END AS NewRetailPrice,
	|		SettingPricesForProductProductRange.ByItemVariant AS ByItemVariant,
	|		SettingPricesForProductProductRange.ByBatch AS ByBatch,
	|		SettingPricesForProductProductRange.ByPackage AS ByPackage
	|	FROM
	|		ExtendedDataTable AS SettingPricesForProductProductRange
	|	WHERE
	|		SettingPricesForProductProductRange.PriceKind = &PriceKind) AS NestedQuery
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&PreviousDayEnd, DAY),
	|			(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PricingVariant,
	|				T.PricingBatch,
	|				T.PricingPackage,
	|				T.PriceKind
	|			FROM
	|				DataTable AS T
	|			WHERE
	|				T.PriceKind = &PriceKind)) AS ItemPricesCrossSectionOfTheLatest
	|		ON NestedQuery.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND NestedQuery.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND NestedQuery.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND NestedQuery.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON NestedQuery.Products = Dimension.Products
	|		AND NestedQuery.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS
	|			CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = NestedQuery.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = NestedQuery.Characteristic
	|WHERE
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) * (NestedQuery.NewRetailPrice -
	|		ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|
	|ORDER BY
	|	NestedQuery.LineNumber";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailDB()
	QueryText = 
	"SELECT
	|	PriceSetup.Number         AS Number,
	|	PriceSetup.Date          AS Date,
	|	PriceSetup.Ref        AS Ref,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsiblePresentation,
	|	&Organization                           AS Organization,
	|	&Organization                           AS Vendor,
	|	&RetailStore                      AS Recipient,
	|	&RetailStore                      AS RecipientPresentation1
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.Ref AS Ref,
	|	SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.Characteristic AS Characteristic,
	|	SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice
	|INTO PricesOfProductRange
	|FROM
	|	Document.PriceSetup.Goods AS SettingPricesForProductProductRange
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &PriceSetup
	|	AND SettingPricesForProductProductRange.PriceKind = &PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PricesOfProductRange.LineNumber                     AS LineNumber,
	|	PricesOfProductRange.Products                    AS Products,
	|	CatalogProducts.Code                             AS Code,
	|	CatalogProducts.SKU                         AS SKU,
	|	CatalogProducts.DescriptionFull              AS FullNameOfProduct_,
	|	CatalogProducts.UnitOfMeasure.Presentation  AS UnitOfMeasure,
	|	PricesOfProductRange.Characteristic                  AS Characteristic,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1                                                      AS ZoomRatio,
	|	PricesOfProductRange.NewRetailPrice               AS RetailPrice,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPrice - (ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))) AS CostDeviation,
	|	ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|	
	|	LEFT JOIN PricesOfProductRange
	|	ON PricesOfProductRange.Ref = PriceSetup.Ref
	|		
	|	LEFT JOIN InformationRegister.ItemsPrices.SliceLast(&PreviousDayEnd, (Products, Characteristic, PriceKind) IN (SELECT T.Products, T.Characteristic, T.PriceKind FROM Document.PriceSetup.Goods AS T WHERE T.Ref = &PriceSetup AND T.PriceKind = &PriceKind)) AS ItemPricesCrossSectionOfTheLatest
	|	ON PricesOfProductRange.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND PricesOfProductRange.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|		
	|	LEFT JOIN
	|	InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON PricesOfProductRange.Products = Dimension.Products
	|		AND PricesOfProductRange.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|	LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = PricesOfProductRange.Products
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = PricesOfProductRange.Characteristic
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPrice - (ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))) <> 0
	|	
	|ORDER BY
	|	PricesOfProductRange.LineNumber
	|
	|";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailDB2_5()
	QueryText = 
	"SELECT
	|	PriceSetup.Number AS Number,
	|	PriceSetup.Date AS Date,
	|	PriceSetup.Ref AS Ref,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsiblePresentation,
	|	&Organization AS Organization,
	|	&Organization AS Vendor,
	|	&RetailStore AS Recipient,
	|	&RetailStore AS RecipientPresentation1
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.Ref AS Ref,
	|	SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|	SettingPricesForProductProductRange.PricingBatch AS PricingBatch,
	|	SettingPricesForProductProductRange.PricingPackage AS PricingPackage,
	|	SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice,
	|	SettingPricesForProductProductRange.Price AS NewRetailPriceByPackage
	|INTO PricesOfProductRange
	|FROM
	|	Document.PriceSetup.Goods2_5 AS SettingPricesForProductProductRange
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &PriceSetup
	|	AND SettingPricesForProductProductRange.PriceKind = &PriceKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	PricesOfProductRange.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO ProductsTable
	|FROM
	|	PricesOfProductRange AS PricesOfProductRange
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON PricesOfProductRange.Products.ProductKind = ItemKinds.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON PricesOfProductRange.Products = CatProducts_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PricesOfProductRange.Ref AS Ref,
	|	PricesOfProductRange.LineNumber AS LineNumber,
	|	PricesOfProductRange.Products AS Products,
	|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|	PricesOfProductRange.PricingVariant AS PricingVariant,
	|	PricesOfProductRange.PricingBatch AS PricingBatch,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	PricesOfProductRange.PricingPackage AS PricingPackage,
	|	PricesOfProductRange.NewRetailPrice AS NewRetailPrice,
	|	PricesOfProductRange.NewRetailPriceByPackage AS NewRetailPriceByPackage,
	|	ProductsTable.ByPackage AS ByPackage,
	|	ProductsTable.ByItemVariant AS ByItemVariant,
	|	ProductsTable.ByBatch AS ByBatch
	|INTO PricesOfProductRangeAugmented
	|FROM
	|	PricesOfProductRange AS PricesOfProductRange
	|		LEFT JOIN ProductsTable AS ProductsTable
	|		ON PricesOfProductRange.Products = ProductsTable.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON PricesOfProductRange.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND ProductsTable.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON PricesOfProductRange.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND PricesOfProductRange.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON ProductsTable.ByBatch
	|		AND PricesOfProductRange.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND PricesOfProductRange.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PricesOfProductRange.LineNumber AS LineNumber,
	|	PricesOfProductRange.Products AS Products,
	|	CatalogProducts.Code AS Code,
	|	CatalogProducts.SKU AS SKU,
	|	CatalogProducts.DescriptionFull AS FullNameOfProduct_,
	|	CASE
	|		WHEN PricesOfProductRange.ByPackage
	|			THEN PricesOfProductRange.PricingPackage.Presentation
	|		ELSE CatalogProducts.UnitOfMeasure.Presentation
	|	END AS UnitOfMeasure,
	|	PricesOfProductRange.Series AS Series,
	|	PricesOfProductRange.Characteristic AS Characteristic,
	|	PricesOfProductRange.PricingVariant AS PricingVariant,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1 AS ZoomRatio,
	|	CASE
	|		WHEN PricesOfProductRange.ByPackage
	|			THEN PricesOfProductRange.NewRetailPriceByPackage
	|		ELSE PricesOfProductRange.NewRetailPrice
	|	END AS RetailPrice,
	|	CASE
	|		WHEN PricesOfProductRange.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPriceByPackage
	|				- ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0))
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))
	|	END AS CostDeviation,
	|	CASE
	|		WHEN PricesOfProductRange.ByPackage
	|			THEN ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)
	|		ELSE ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)
	|	END AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count,
	|	PricesOfProductRange.ByPackage,
	|	PricesOfProductRange.ByItemVariant,
	|	PricesOfProductRange.ByBatch
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|		LEFT JOIN PricesOfProductRangeAugmented AS PricesOfProductRange
	|		ON PricesOfProductRange.Ref = PriceSetup.Ref
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&PreviousDayEnd, (Products,
	|			PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PricingVariant,
	|				T.PricingBatch,
	|				T.PricingPackage,
	|				T.PriceKind
	|			FROM
	|				Document.PriceSetup.Goods2_5 AS T
	|			WHERE
	|				T.Ref = &PriceSetup
	|				AND T.PriceKind = &PriceKind)) AS ItemPricesCrossSectionOfTheLatest
	|		ON PricesOfProductRange.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND PricesOfProductRange.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND PricesOfProductRange.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND PricesOfProductRange.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON PricesOfProductRange.Products = Dimension.Products
	|		AND PricesOfProductRange.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS
	|			CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = PricesOfProductRange.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = PricesOfProductRange.Characteristic
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND CASE
	|		WHEN PricesOfProductRange.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPriceByPackage
	|				- ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)) <> 0
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (PricesOfProductRange.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|	END
	|
	|ORDER BY
	|	PricesOfProductRange.LineNumber";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailDBByAssortment()
	Var QueryText;
	QueryText = 
	"SELECT
	|	PriceSetup.Number         AS Number,
	|	PriceSetup.Date          AS Date,
	|	PriceSetup.Ref        AS Ref,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsiblePresentation,
	|	&Organization                           AS Organization,
	|	&Organization                           AS Vendor,
	|	&RetailStore                      AS Recipient,
	|	&RetailStore                      AS RecipientPresentation1
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductRange.Products AS Products,
	|	ProductRange.PriceKind      AS PriceKind
	|INTO ProductTypesOfPrices
	|FROM
	|	InformationRegister.ProductRange.SliceLast(
	|			ENDOFPERIOD(&DocumentDate, DAY),
	|			PlanningObject = &PlanningObject
	|				AND Products IN
	|					(SELECT
	|						T.Products
	|					FROM
	|						Document.PriceSetup.Goods AS T
	|					WHERE
	|						T.Ref = &PriceSetup)) AS ProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.Ref                                                AS Ref,
	|	SettingPricesForProductProductRange.LineNumber                                           AS LineNumber,
	|	SettingPricesForProductProductRange.Products                                          AS Products,
	|	SettingPricesForProductProductRange.Characteristic                                        AS Characteristic,
	|	SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice,
	|	SettingPricesForProductProductRange.PriceKind AS PriceKind
	|INTO SettingPricesProductsAssortment
	|FROM
	|	Document.PriceSetup.Goods AS SettingPricesForProductProductRange
	|	INNER JOIN ProductTypesOfPrices AS ProductTypesOfPrices
	|	ON ProductTypesOfPrices.Products = SettingPricesForProductProductRange.Products
	|	AND ProductTypesOfPrices.PriceKind = SettingPricesForProductProductRange.PriceKind
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &PriceSetup
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesProductsAssortment.LineNumber              AS LineNumber,
	|	SettingPricesProductsAssortment.Products             AS Products,
	|	CatalogProducts.Code                             AS Code,
	|	CatalogProducts.SKU                         AS SKU,
	|	CatalogProducts.DescriptionFull              AS FullNameOfProduct_,
	|	CatalogProducts.UnitOfMeasure.Presentation  AS UnitOfMeasure,
	|	SettingPricesProductsAssortment.Characteristic           AS Characteristic,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1                                                      AS ZoomRatio,
	|	SettingPricesProductsAssortment.NewRetailPrice        AS RetailPrice,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) * (SettingPricesProductsAssortment.NewRetailPrice - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) AS CostDeviation,
	|	ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1) AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|	LEFT JOIN SettingPricesProductsAssortment
	|	ON PriceSetup.Ref = SettingPricesProductsAssortment.Ref
	|	LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|			&PreviousDayEnd,
	|			(Products, PriceKind) IN
	|				(SELECT
	|					T.Products,
	|					T.PriceKind
	|				FROM
	|					ProductTypesOfPrices AS T
	|				)) AS ItemPricesCrossSectionOfTheLatest
	|	ON (SettingPricesProductsAssortment.Products = ItemPricesCrossSectionOfTheLatest.Products)
	|		AND (SettingPricesProductsAssortment.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic)
	|		AND (SettingPricesProductsAssortment.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind)
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		SettingPricesProductsAssortment.Products = Dimension.Products
	|		AND SettingPricesProductsAssortment.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|	LEFT JOIN AccumulationRegister.CompanyGoods.Balance(
	|			&PreviousDayEnd,
	|			Organization = &Organization) AS CompanyGoodsBalance
	|	ON (Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes)
	|
	|	LEFT JOIN Catalog.Products AS CatalogProducts
	|	ON CatalogProducts.Ref = SettingPricesProductsAssortment.Products
	|
	|	LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|	ON CatalogOfNomenlatureCharacteristics.Ref = SettingPricesProductsAssortment.Characteristic
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) * (SettingPricesProductsAssortment.NewRetailPrice - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|ORDER BY
	|	SettingPricesProductsAssortment.LineNumber
	|";
	Return QueryText
EndFunction

Function TextOfRequestForRevaluationOfGoodsInRetailDBByAssortment2_5()

	QueryText = 
	"SELECT
	|	PriceSetup.Number AS Number,
	|	PriceSetup.Date AS Date,
	|	PriceSetup.Ref AS Ref,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsiblePresentation,
	|	&Organization AS Organization,
	|	&Organization AS Vendor,
	|	&RetailStore AS Recipient,
	|	&RetailStore AS RecipientPresentation1
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductRange.Products AS Products,
	|	ProductRange.PriceKind AS PriceKind
	|INTO ProductTypesOfPrices
	|FROM
	|	InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&DocumentDate, DAY),
	|		PlanningObject = &PlanningObject
	|	AND Products IN
	|		(SELECT
	|			T.Products
	|		FROM
	|			Document.PriceSetup.Goods2_5 AS T
	|		WHERE
	|			T.Ref = &PriceSetup)) AS ProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesForProductProductRange.Ref AS Ref,
	|	SettingPricesForProductProductRange.LineNumber AS LineNumber,
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|	SettingPricesForProductProductRange.PricingBatch AS PricingBatch,
	|	SettingPricesForProductProductRange.PricingPackage AS PricingPackage,
	|	SettingPricesForProductProductRange.Price / ISNULL(&QueryTextPackagingFactor2, 1) AS NewRetailPrice,
	|	SettingPricesForProductProductRange.Price AS NewRetailPriceByPackage,
	|	SettingPricesForProductProductRange.PriceKind AS PriceKind
	|INTO SettingPricesProductsAssortment
	|FROM
	|	Document.PriceSetup.Goods2_5 AS SettingPricesForProductProductRange
	|		INNER JOIN ProductTypesOfPrices AS ProductTypesOfPrices
	|		ON ProductTypesOfPrices.Products = SettingPricesForProductProductRange.Products
	|		AND ProductTypesOfPrices.PriceKind = SettingPricesForProductProductRange.PriceKind
	|WHERE
	|	SettingPricesForProductProductRange.Ref = &PriceSetup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SettingPricesProductsAssortment.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByItemVariant,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ByPackage,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO ProductsTable
	|FROM
	|	SettingPricesProductsAssortment AS SettingPricesProductsAssortment
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON SettingPricesProductsAssortment.Products.ProductKind = ItemKinds.Ref
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON SettingPricesProductsAssortment.Products = CatProducts_.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesProductsAssortment.Ref AS Ref,
	|	SettingPricesProductsAssortment.LineNumber AS LineNumber,
	|	SettingPricesProductsAssortment.Products AS Products,
	|	ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|	SettingPricesProductsAssortment.PricingVariant AS PricingVariant,
	|	SettingPricesProductsAssortment.PricingBatch AS PricingBatch,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	SettingPricesProductsAssortment.PricingPackage AS PricingPackage,
	|	SettingPricesProductsAssortment.NewRetailPrice AS NewRetailPrice,
	|	SettingPricesProductsAssortment.NewRetailPriceByPackage AS NewRetailPriceByPackage,
	|	SettingPricesProductsAssortment.PriceKind AS PriceKind,
	|	ProductsTable.ByPackage AS ByPackage,
	|	ProductsTable.ByItemVariant AS ByItemVariant,
	|	ProductsTable.ByBatch AS ByBatch
	|INTO SettingPricesProductsAssortmentAugmented
	|FROM
	|	SettingPricesProductsAssortment AS SettingPricesProductsAssortment
	|		LEFT JOIN ProductsTable AS ProductsTable
	|		ON SettingPricesProductsAssortment.Products = ProductsTable.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON SettingPricesProductsAssortment.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND ProductsTable.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON SettingPricesProductsAssortment.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		AND SettingPricesProductsAssortment.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON ProductsTable.ByBatch
	|		AND SettingPricesProductsAssortment.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND SettingPricesProductsAssortment.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesProductsAssortment.LineNumber AS LineNumber,
	|	SettingPricesProductsAssortment.Products AS Products,
	|	CatalogProducts.Code AS Code,
	|	CatalogProducts.SKU AS SKU,
	|	CatalogProducts.DescriptionFull AS FullNameOfProduct_,
	|	CASE
	|		WHEN SettingPricesProductsAssortment.ByPackage
	|			THEN SettingPricesProductsAssortment.PricingPackage.Presentation
	|		ELSE CatalogProducts.UnitOfMeasure.Presentation
	|	END AS UnitOfMeasure,
	|	SettingPricesProductsAssortment.Series AS Series,
	|	SettingPricesProductsAssortment.Characteristic AS Characteristic,
	|	SettingPricesProductsAssortment.PricingVariant AS PricingVariant,
	|	CatalogOfNomenlatureCharacteristics.DescriptionFull AS FullNameOfCharacteristic,
	|	1 AS ZoomRatio,
	|	CASE
	|		WHEN SettingPricesProductsAssortment.ByPackage
	|			THEN SettingPricesProductsAssortment.NewRetailPriceByPackage
	|		ELSE SettingPricesProductsAssortment.NewRetailPrice
	|	END AS RetailPrice,
	|	CASE
	|		WHEN SettingPricesProductsAssortment.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) *
	|				(SettingPricesProductsAssortment.NewRetailPriceByPackage - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0))
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (SettingPricesProductsAssortment.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1))
	|	END AS CostDeviation,
	|	CASE
	|		WHEN SettingPricesProductsAssortment.ByPackage
	|			THEN ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)
	|		ELSE ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)
	|	END AS RetailPriceIsOld,
	|	ISNULL(CompanyGoodsBalance.CountBalance, 0) AS Count,
	|	SettingPricesProductsAssortment.ByPackage AS ByPackage,
	|	SettingPricesProductsAssortment.ByItemVariant AS ByItemVariant,
	|	SettingPricesProductsAssortment.ByBatch AS ByBatch
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|		LEFT JOIN SettingPricesProductsAssortmentAugmented AS SettingPricesProductsAssortment
	|		ON PriceSetup.Ref = SettingPricesProductsAssortment.Ref
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(&PreviousDayEnd, (Products, PriceKind) IN
	|			(SELECT
	|				T.Products,
	|				T.PriceKind
	|			FROM
	|				ProductTypesOfPrices AS T)) AS ItemPricesCrossSectionOfTheLatest
	|		ON SettingPricesProductsAssortment.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND SettingPricesProductsAssortment.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND SettingPricesProductsAssortment.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND SettingPricesProductsAssortment.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND SettingPricesProductsAssortment.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON SettingPricesProductsAssortment.Products = Dimension.Products
	|		AND SettingPricesProductsAssortment.Characteristic = Dimension.Characteristic
	|		AND &RetailStore = Dimension.StorageLocation
	|		LEFT JOIN AccumulationRegister.CompanyGoods.Balance(&PreviousDayEnd, Organization = &Organization) AS
	|			CompanyGoodsBalance
	|		ON Dimension.DimensionKey = CompanyGoodsBalance.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON CatalogProducts.Ref = SettingPricesProductsAssortment.Products
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogOfNomenlatureCharacteristics
	|		ON CatalogOfNomenlatureCharacteristics.Ref = SettingPricesProductsAssortment.Characteristic
	|WHERE
	|	PriceSetup.Ref = &PriceSetup
	|	AND ISNULL(CompanyGoodsBalance.CountBalance, 0) <> 0
	|	AND CASE
	|		WHEN SettingPricesProductsAssortment.ByPackage
	|			THEN ISNULL(CompanyGoodsBalance.CountBalance, 0) *
	|				(SettingPricesProductsAssortment.NewRetailPriceByPackage - ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0)) <> 0
	|		ELSE ISNULL(CompanyGoodsBalance.CountBalance, 0) * (SettingPricesProductsAssortment.NewRetailPrice -
	|			ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor1, 1)) <> 0
	|	END
	|
	|ORDER BY
	|	SettingPricesProductsAssortment.LineNumber";
	Return QueryText
EndFunction

#EndRegion

// The function generates a tabular document with a printed form of retail revaluation.
//
// Returns:
//  SpreadsheetDocument - 
//
Function CreatePrintedFormOfRevaluationOfGoodsInRetailDB(ObjectsArray, PrintObjects, PrintParameters)
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_GoodsRevaluationInRetail_GoodsRevaluationInRetail";
	
	Template = PrintManagement.PrintFormTemplate("Document.PriceSetup.PF_MXL_GoodsRevaluationInRetail");
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(PrintParameters.RetailStore);
	
	FirstDocument = True;
	For Each PriceSetup In ObjectsArray Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = TabDocument.TableHeight + 1;
		
		PreviousDayEnd = EndOfDay(BegOfDay(PriceSetup.Date) - 1);
		BorderEndOfPreviousDay = New Boundary(PreviousDayEnd, BoundaryType.Including);
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(PriceSetup.Date);
		
		Query = New Query;
		Query.SetParameter("PriceSetup", PriceSetup);
		Query.SetParameter("RetailStore",         PrintParameters.RetailStore);
		Query.SetParameter("Organization",              PrintParameters.Organization);
		Query.SetParameter("PreviousDayEnd",      BorderEndOfPreviousDay);
		If ControlProductRange Then
			
			PlanningObject = ProductRangeServer.PlanningObject(PrintParameters.RetailStore);
			Query.SetParameter("PlanningObject", PlanningObject);
			Query.SetParameter("DocumentDate", PriceSetup.Date);
			
			If UsePriceManagementSystem25 Then
				QueryText = TextOfRequestForRevaluationOfGoodsInRetailDBByAssortment2_5();
			Else
				QueryText = TextOfRequestForRevaluationOfGoodsInRetailDBByAssortment();
			EndIf;
			
		Else
			Query.SetParameter("PriceKind",                  PrintParameters.RetailStore.RetailPriceType);
			
			If UsePriceManagementSystem25 Then
				QueryText = TextOfRequestForRevaluationOfGoodsInRetailDB2_5();
			Else
				QueryText = TextOfRequestForRevaluationOfGoodsInRetailDB();
			EndIf;
			
		EndIf;
		
		QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ItemPricesCrossSectionOfTheLatest.Package",
				"ItemPricesCrossSectionOfTheLatest.Products"));
		QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"SettingPricesForProductProductRange.Package",
				"SettingPricesForProductProductRange.Products"));
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		RequestPackageResult = Query.ExecuteBatch(); 
		SetPrivilegedMode(False);
		
		ResultHeader__ = RequestPackageResult[0];
		
		Header = ResultHeader__.Select();
		Header.Next();
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, TemplateArea, Header.Ref);
		TemplateArea.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			Header,
			NStr("vi = 'Đánh giá lại hàng hóa bán lẻ';
				|ru = 'Переоценка товаров в рознице';
				|en = 'Goods revaluation in retail'; fa = 'تجدید ارزیابی کالا در خرده‌فروشی';
				|it = 'Rivalutazione delle merci nella vendita al dettaglio';
				|pl = 'Przeszacowanie towarów w handlu detalicznym';
				|tr = 'Perakende ürünleri yeniden değerleme'", Common.DefaultLanguageCode()));
		TabDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		TemplateArea.Parameters.Fill(Header);
		TemplateArea.Parameters.SupplierPresentation = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintParameters.Organization, Header.Date), "FullDescr,");
		TabDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		TemplateArea.Parameters.RecipientPresentation1 = PrintParameters.RetailStore;
		TabDocument.Put(TemplateArea);
		
		// The header of the table
		ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
		AdditionalColumnName = ColumnOfCodes.ColumnName;
		PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
		OutputCodes = ?(ValueIsFilled(AdditionalColumnName),True, False);
		
		RoomArea = Template.GetArea("TableHeader|RoomArea");
		AreaCodes  = Template.GetArea("TableHeader|AreaCodes");
		DataArea = Template.GetArea("TableHeader|DataArea");
		
		TabDocument.Put(RoomArea);
		If OutputCodes Then
			AreaCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			TabDocument.Join(AreaCodes);
		EndIf;
		TabDocument.Join(DataArea);
		
		// Table row
		RoomArea = Template.GetArea("String|RoomArea");
		AreaCodes  = Template.GetArea("String|AreaCodes");
		DataArea = Template.GetArea("String|DataArea");
		
		TotalCostDeviation = 0;
		LineNumber = 0;
		SelectingProductLines = RequestPackageResult[RequestPackageResult.Count() - 1].Select();
		While SelectingProductLines.Next() Do
			
			If Not ValueIsFilled(SelectingProductLines.FullNameOfProduct_) Then
				Continue;
			EndIf;
			
			LineNumber = LineNumber + 1;
			
			RoomArea.Parameters.LineNumber = LineNumber;
			TabDocument.Put(RoomArea);
			If OutputCodes Then
				If AdditionalColumnName = "SKU" Then
					AreaCodes.Parameters.SKU = SelectingProductLines.SKU;
				Else
					AreaCodes.Parameters.SKU = SelectingProductLines.Code;
				EndIf;
				TabDocument.Join(AreaCodes);
			EndIf;
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
			DataArea.Parameters.Fill(SelectingProductLines);

			PrintSeries 		= Undefined;
			
			If UsePriceManagementSystem25 Then
				If ValueIsFilled(SelectingProductLines.ByBatch) And SelectingProductLines.ByBatch Then
					PrintSeries 		= SelectingProductLines.Series;
				EndIf;
			EndIf;
			
			DataArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectingProductLines.FullNameOfProduct_,
				SelectingProductLines.FullNameOfCharacteristic,
				,
				PrintSeries,
				AdditionalParametersProductPresentation);
			TabDocument.Join(DataArea);
			
			TotalCostDeviation = TotalCostDeviation + SelectingProductLines.CostDeviation;
			
		EndDo;
		
		// Total
		RoomArea = Template.GetArea("Total|RoomArea");
		AreaCodes  = Template.GetArea("Total|AreaCodes");
		DataArea = Template.GetArea("Total|DataArea");
		
		TabDocument.Put(RoomArea);
		If OutputCodes Then
			TabDocument.Join(AreaCodes);
		EndIf;
		DataArea.Parameters.TotalCostDeviation = PrintFormGeneration.SumFormat(TotalCostDeviation, PrintParameters.RetailStore.RetailPriceType.PriceCurrency);
		TabDocument.Join(DataArea);
		
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.Fill(Header);
		TabDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, PriceSetup);
		
	EndDo;
	
	Return TabDocument;
	
EndFunction

// The function generates a tabular document with a printed form of retail revaluation.
//
// Returns:
//  SpreadsheetDocument - .
//
Function CreatePrintedFormOfRevaluationOfGoodsInRetailTT(ObjectsArray, PrintObjects, PrintParameters)
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_GoodsRevaluationInRetail_GoodsRevaluationInRetail";
	
	Template = PrintManagement.PrintFormTemplate("Document.PriceSetup.PF_MXL_GoodsRevaluationInRetail");
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(PrintParameters.RetailStore);
	
	DataForPrint = GetFromTempStorage(PrintParameters.AddressDataForPrintingInTheTemporaryStorage);
	
	UsePriceManagementSystem25 = False;
	If Not DataForPrint.Property("UsePriceManagementSystem25", UsePriceManagementSystem25) Then
		UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(DataForPrint.ValidPriceDate + 1);
	EndIf;
	
	TMCommonUse.NumberValueTable(DataForPrint.Goods, "LineNumber");
	
	RowNumberStart = TabDocument.TableHeight + 1;
	
	Query = New Query;
	Query.SetParameter("Goods",                   DataForPrint.Goods);
	Query.SetParameter("RetailStore",         PrintParameters.RetailStore);
	Query.SetParameter("Organization",              PrintParameters.Organization);
	Query.SetParameter("PreviousDayEnd",      DataForPrint.ValidPriceDate);
	If ControlProductRange Then
		
		PlanningObject = ProductRangeServer.PlanningObject(PrintParameters.RetailStore);
		Query.SetParameter("PlanningObject", PlanningObject);
		Query.SetParameter("DocumentDate", CurrentSessionDate());
		
		If UsePriceManagementSystem25 Then
			QueryText = TextOfRequestForRevaluationOfGoodsInRetailTTByAssortment2_5();
		Else
			QueryText = TextOfRequestForRevaluationOfGoodsInRetailTTByAssortment();
		EndIf;
	Else
		Query.SetParameter("PriceKind",                  PrintParameters.RetailStore.RetailPriceType);
		If UsePriceManagementSystem25 Then
			QueryText = TextOfRequestForRevaluationOfGoodsInRetailTT2_5();
		Else
			QueryText = TextOfRequestForRevaluationOfGoodsInRetailTT();
		EndIf;
	EndIf;
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SettingPricesForProductProductRange.Package",
			"SettingPricesForProductProductRange.Products"));
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	RequestPackageResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.TitleText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đánh giá lại hàng hóa bán lẻ trong %1';
			|ru = 'Переоценка товаров в рознице за %1';
			|en = 'Goods revaluation in retail for %1'; fa = 'Goods revaluation in retail for %1';
			|it = 'Rivalutazione delle merci in vendita al dettaglio nel %1';
			|pl = 'Przeszacowanie towarów w handlu detalicznym za %1';
			|tr = '%1 için perakende ürünleri yeniden değerleme'", Common.DefaultLanguageCode()),
		Format(DataForPrint.ValidPriceDate, "DLF=D"));
	TabDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Vendor");
	TemplateArea.Parameters.Fill(PrintParameters);
	TemplateArea.Parameters.SupplierPresentation = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintParameters.Organization, CurrentSessionDate()), "FullDescr,");
	TabDocument.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("Customer");
	TemplateArea.Parameters.RecipientPresentation1 = PrintParameters.RetailStore;
	TabDocument.Put(TemplateArea);
	
	// The header of the table
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumnName = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ?(ValueIsFilled(AdditionalColumnName),True, False);
	
	RoomArea = Template.GetArea("TableHeader|RoomArea");
	AreaCodes  = Template.GetArea("TableHeader|AreaCodes");
	DataArea = Template.GetArea("TableHeader|DataArea");
	
	TabDocument.Put(RoomArea);
	If OutputCodes Then
		AreaCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		TabDocument.Join(AreaCodes);
	EndIf;
	TabDocument.Join(DataArea);
	
	// Table row
	RoomArea = Template.GetArea("String|RoomArea");
	AreaCodes  = Template.GetArea("String|AreaCodes");
	DataArea = Template.GetArea("String|DataArea");
	
	TotalCostDeviation = 0;
	LineNumber = 0;
	ProductResult = RequestPackageResult[RequestPackageResult.Count() - 1]; // QueryResult
	SelectingProductLines = ProductResult.Select();
	While SelectingProductLines.Next() Do
		
		LineNumber = LineNumber + 1;
		
		RoomArea.Parameters.LineNumber = LineNumber;
		TabDocument.Put(RoomArea);
		If OutputCodes Then
			If AdditionalColumnName = "SKU" Then
				AreaCodes.Parameters.SKU = SelectingProductLines.SKU;
			Else
				AreaCodes.Parameters.SKU = SelectingProductLines.Code;
			EndIf;
			TabDocument.Join(AreaCodes);
		EndIf;
		
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
		DataArea.Parameters.Fill(SelectingProductLines);

		PrintSeries 		= Undefined;
		
		If UsePriceManagementSystem25 Then
			If ValueIsFilled(SelectingProductLines.ByBatch) And SelectingProductLines.ByBatch Then
				PrintSeries 		= SelectingProductLines.Series;
			EndIf;
		EndIf;
		
		DataArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
			SelectingProductLines.FullNameOfProduct_,
			SelectingProductLines.FullNameOfCharacteristic,
			,
			PrintSeries,
			AdditionalParametersProductPresentation);
		TabDocument.Join(DataArea);
		
		TotalCostDeviation = TotalCostDeviation + SelectingProductLines.CostDeviation;
		
	EndDo;
	
	// Total
	RoomArea = Template.GetArea("Total|RoomArea");
	AreaCodes  = Template.GetArea("Total|AreaCodes");
	DataArea = Template.GetArea("Total|DataArea");
	
	TabDocument.Put(RoomArea);
	If OutputCodes Then
		TabDocument.Join(AreaCodes);
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Warehouses.RetailPriceType.PriceCurrency AS PriceCurrency
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref = &Warehouse");
	Query.SetParameter("Warehouse", PrintParameters.RetailStore);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	DataArea.Parameters.TotalCostDeviation = PrintFormGeneration.SumFormat(TotalCostDeviation, Selection.PriceCurrency);
	TabDocument.Join(DataArea);
	
	PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, Documents.PriceSetup.EmptyRef());
	
	Return TabDocument;
	
EndFunction

// The function generates a tabular document with a printed form of retail revaluation.
//
// Returns:
//  SpreadsheetDocument - 
//
Function CreatePrintedFormOfRevaluationOfGoodsInRetail(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(PrintParameters.AddressDataForPrintingInTheTemporaryStorage) Then
		Return CreatePrintedFormOfRevaluationOfGoodsInRetailTT(ObjectsArray, PrintObjects, PrintParameters);
	Else
		Return CreatePrintedFormOfRevaluationOfGoodsInRetailDB(ObjectsArray, PrintObjects, PrintParameters);
	EndIf;

EndFunction

// Parameters:
// 	Parameters - See NewPrintParameterStructure
// 
Procedure PrintTabularPartSettingProductPrices(Parameters)
	
	// The header of the table
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumnName = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ?(ValueIsFilled(AdditionalColumnName), True, False);
	
	NumberHeader  = Parameters.Template.GetArea("TableHeader|RoomArea");
	CodeHeader   = Parameters.Template.GetArea("TableHeader|AreaCodes");
	Header_Product   = Parameters.Template.GetArea("TableHeader|ProductArea");
	PriceTypeHeader = Parameters.Template.GetArea("TableHeader|" + 
		?(Not Parameters.PrintParameters.DisplayHeader,"PriceViewAreaUniqueIdentifier","PriceViewArea"));
	If Parameters.UsePriceManagementSystem25 Then
		UniqueIdentifiersHeader = Parameters.Template.GetArea("TableHeader|UniqueIdentifiers25");
	Else
		UniqueIdentifiersHeader = Parameters.Template.GetArea("TableHeader|UniqueIdentifiers");
	EndIf;
	
	Parameters.TabDocument.Put(NumberHeader);
	If OutputCodes Then
		CodeHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		Parameters.TabDocument.Join(CodeHeader);
	EndIf;
	If Not Parameters.PrintParameters.DisplayHeader Then
		Parameters.TabDocument.Join(UniqueIdentifiersHeader);
	EndIf;
	Parameters.TabDocument.Join(Header_Product);
	
	Table_ = New ValueTable;
	Table_.Columns.Add("PriceKind");
	Table_.Columns.Add("AreaTemplate");
	Table_.Columns.Add("WithdrawAmountOfChange");
	Table_.Columns.Add("DisplayPercentageOfChange");
	Table_.Columns.Add("DisplayOldPrice");
	
	SelectionByPriceType = Parameters.QueryResult.TypesOfPrices.Select();
	While SelectionByPriceType.Next() Do
		
		IsNew                          = Table_.Add();
		IsNew.PriceKind                  = SelectionByPriceType.PriceKind;
		IsNew.DisplayPercentageOfChange = False;
		IsNew.WithdrawAmountOfChange   = False;
		IsNew.DisplayOldPrice       = False;
		
		FoundRows = Parameters.SettingsTree.Rows.FindRows(New Structure("Parameter", SelectionByPriceType.PriceKind), False);
		For Each PriceKind In FoundRows Do
			
			For Each Column In PriceKind.Rows Do
				
				If Column.Parameter = "OldPrice" And Column.Print Then
					IsNew.DisplayOldPrice = True;
				EndIf;
				
				If Column.Parameter = "AmountOfChange" And Column.Print Then
					IsNew.WithdrawAmountOfChange = True;
				EndIf;
				
				If Column.Parameter = "ChangePercentage" And Column.Print Then
					IsNew.DisplayPercentageOfChange = True;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		If IsNew.WithdrawAmountOfChange Then
			
			If IsNew.DisplayPercentageOfChange And IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceChangePercentageChangeAmountUniqueIdentifier",
					"AreaPriceViewOldPriceChangePercentageChangeAmount"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceChangePercentageChangeAmountUniqueIdentifier",
					"AreaPriceViewOldPriceChangePercentageChangeAmount"));
			ElsIf IsNew.DisplayPercentageOfChange And Not IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaChangePercentageChangeAmountUniqueIdentifier",
					"AreaPriceViewChangePercentageChangeAmount"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|AreaPriceViewChangePercentageChangeAmount");
			ElsIf Not IsNew.DisplayPercentageOfChange And IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceAmountOfChangeUniqueIdentifier",
					"AreaPriceViewOldPriceAmountOfChange"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceAmountOfChangeUniqueIdentifier",
					"AreaPriceViewOldPriceAmountOfChange"));
			ElsIf Not IsNew.DisplayPercentageOfChange And Not IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaChangeAmountUniqueIdentifier",
					"AreaPriceViewAmountOfChange"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaChangeAmountUniqueIdentifier",
					"AreaPriceViewAmountOfChange"));
			EndIf;
			
		Else
			
			If IsNew.DisplayPercentageOfChange And IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceChangePercentageUniqueIdentifier",
					"AreaPriceViewOldPricePercentageChange"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceChangePercentageUniqueIdentifier",
					"AreaPriceViewOldPricePercentageChange"));
			ElsIf IsNew.DisplayPercentageOfChange And Not IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaChangePercentageUniqueIdentifier",
					"PriceViewAreaPercentageOfChange"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|PriceViewAreaPercentageOfChange");
			ElsIf Not IsNew.DisplayPercentageOfChange And IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceUniqueIdentifier",
					"AreaPriceViewOldPrice"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaOldPriceUniqueIdentifier",
					"AreaPriceViewOldPrice"));
			ElsIf Not IsNew.DisplayPercentageOfChange And Not IsNew.DisplayOldPrice Then
				PriceTypeHeader       = Parameters.Template.GetArea("TableHeader|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaUniqueIdentifier",
					"PriceViewArea"));
				IsNew.AreaTemplate = Parameters.Template.GetArea("String|" + 
					?(Not Parameters.PrintParameters.DisplayHeader,
					"PriceViewAreaUniqueIdentifier",
					"PriceViewArea"));
			EndIf;
			
		EndIf;
		
		PriceTypeHeader.Parameters.PriceKind = SelectionByPriceType.PriceKind;
		Parameters.TabDocument.Join(PriceTypeHeader);
		
	EndDo;
	
	Areas = New Structure();
	Areas.Insert("RoomArea", Parameters.Template.GetArea("String|RoomArea"));
	Areas.Insert("AreaCodes", Parameters.Template.GetArea("String|AreaCodes"));
	Areas.Insert("ProductArea", Parameters.Template.GetArea("String|ProductArea"));
	If Parameters.UsePriceManagementSystem25 Then
		Areas.Insert("UniqueIdentifiersArea", Parameters.Template.GetArea("String|UniqueIdentifiers25"));
	Else
		Areas.Insert("UniqueIdentifiersArea", Parameters.Template.GetArea("String|UniqueIdentifiers"));
	EndIf;
	
	LineNumber = 0;
	
	SelectionByProductType_ = Parameters.QueryResult.Products.Select(QueryResultIteration.ByGroups);
	While SelectionByProductType_.Next() Do
		
		If Not ValueIsFilled(SelectionByProductType_.Products) Then
			Continue;
		EndIf;
		
		SelectionByCharacteristics = SelectionByProductType_.Select(QueryResultIteration.ByGroups);
		While SelectionByCharacteristics.Next() Do
		
			If Parameters.UsePriceManagementSystem25 Then
				
				SelectionBySeries = SelectionByCharacteristics.Select(QueryResultIteration.ByGroups);
				While SelectionBySeries.Next() Do
					SampleByPackage = SelectionBySeries.Select(QueryResultIteration.ByGroups);
					While SampleByPackage.Next() Do
						FragmentDisplayTabularPartInPrintedFormSettingProductPrices(Parameters, SampleByPackage, OutputCodes, Table_, AdditionalColumnName, Areas, LineNumber);
					EndDo;
				EndDo;
				
			Else
				FragmentDisplayTabularPartInPrintedFormSettingProductPrices(Parameters, SelectionByCharacteristics, OutputCodes, Table_, AdditionalColumnName, Areas, LineNumber);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure


Procedure FragmentDisplayTabularPartInPrintedFormSettingProductPrices(Parameters, SelectionByCharacteristics, Val OutputCodes, Val Table_, Val AdditionalColumnName, Areas, LineNumber)

	LineNumber = LineNumber + 1;
	Areas.RoomArea.Parameters.LineNumber = LineNumber;
	Parameters.TabDocument.Put(Areas.RoomArea);

	If OutputCodes Then
		
		If AdditionalColumnName = "SKU" Then
			Areas.AreaCodes.Parameters.SKU = SelectionByCharacteristics.SKU;
		Else
			Areas.AreaCodes.Parameters.SKU = SelectionByCharacteristics.Code;
		EndIf;
		
		Parameters.TabDocument.Join(Areas.AreaCodes);
		
	EndIf;
	
	If Not Parameters.PrintParameters.DisplayHeader Then
		Areas.UniqueIdentifiersArea.Parameters.UniqueProductIdentifier   = String(SelectionByCharacteristics.Products.UUID());
		If Parameters.UsePriceManagementSystem25 Then
			Areas.UniqueIdentifiersArea.Parameters.UniqueIdentifierCharacteristic = String(SelectionByCharacteristics.PricingVariant.UUID());
			Areas.UniqueIdentifiersArea.Parameters.UniqueIdentifierSeries = String(SelectionByCharacteristics.PricingBatch.UUID());
			Areas.UniqueIdentifiersArea.Parameters.UniqueIdentifierPackaging = String(SelectionByCharacteristics.PricingPackage.UUID());
		Else
			Areas.UniqueIdentifiersArea.Parameters.UniqueIdentifierCharacteristic = String(SelectionByCharacteristics.Characteristic.UUID());
		EndIf;
		Parameters.TabDocument.Join(Areas.UniqueIdentifiersArea);
	EndIf;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Areas.ProductArea.Parameters.Fill(SelectionByCharacteristics);
	If Parameters.UsePriceManagementSystem25 Then
		
		Areas.ProductArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
			SelectionByCharacteristics.FullNameOfProduct_,
			SelectionByCharacteristics.FullNameOfCharacteristic,
			SelectionByCharacteristics.PricingPackage,
			SelectionByCharacteristics.PricingBatch,
			AdditionalParametersProductPresentation);
		
	Else
			
		Areas.ProductArea.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
			SelectionByCharacteristics.FullNameOfProduct_,
			SelectionByCharacteristics.FullNameOfCharacteristic,
			,
			,
			AdditionalParametersProductPresentation);
			
	EndIf;
	Parameters.TabDocument.Join(Areas.ProductArea);
	
	SelectionByPriceType = SelectionByCharacteristics.Select();
	For Each SpecificationRow In Table_ Do
		
		SelectionByPriceType.Reset();
		If SelectionByPriceType.FindNext(New Structure("PriceKind", SpecificationRow.PriceKind)) Then
			
			PriceViewArea = SpecificationRow.AreaTemplate; // SpreadsheetDocument - 
			
			PriceViewArea.Parameters.Price = SelectionByPriceType.Price;
			
			If SpecificationRow.DisplayOldPrice Then
				PriceViewArea.Parameters.OldPrice = SelectionByPriceType.OldPrice;
			EndIf;
			
			If SpecificationRow.WithdrawAmountOfChange Then
				PriceViewArea.Parameters.AmountOfChange = SelectionByPriceType.Price - SelectionByPriceType.OldPrice;
			EndIf;
			
			If SpecificationRow.DisplayPercentageOfChange Then
				PriceViewArea.Parameters.ChangePercentage = SelectionByPriceType.ChangePercentage;
			EndIf;
			
			If ValueIsFilled(SelectionByPriceType.Package) Then
				PriceViewArea.Parameters.UnitOfMeasure = SelectionByPriceType.Package;
			Else
				PriceViewArea.Parameters.UnitOfMeasure = SelectionByPriceType.UnitOfMeasure;
			EndIf;
			
			If Not Parameters.PrintParameters.DisplayHeader Then
				PriceViewArea.Parameters.UniqueIdentifierUnitOfMeasurement = String(SelectionByPriceType.Package.UUID());
			EndIf;
			
		Else
			
			PriceViewArea = SpecificationRow.AreaTemplate; // SpreadsheetDocument - 
			
			PriceViewArea.Parameters.Price = 0;
			
			If SpecificationRow.DisplayOldPrice Then
				PriceViewArea.Parameters.OldPrice = 0;
			EndIf;
			
			If SpecificationRow.WithdrawAmountOfChange Then
				PriceViewArea.Parameters.AmountOfChange = 0;
			EndIf;
			
			If SpecificationRow.DisplayPercentageOfChange Then
				PriceViewArea.Parameters.ChangePercentage = 0;
			EndIf;
			
			PriceViewArea.Parameters.UnitOfMeasure = Undefined;
			
			If Not Parameters.PrintParameters.DisplayHeader Then
				PriceViewArea.Parameters.UniqueIdentifierUnitOfMeasurement = String(Catalogs.PackagesAndUnitsOfMeasure.EmptyRef().UUID());
			EndIf;
			
		EndIf;
		
		Parameters.TabDocument.Join(PriceViewArea);
		
	EndDo;
EndProcedure


// The constructor function of the print settings
// 
// Returns:
// 	Structure - Contains:
// 		* RowNumberStart - Number - 
// 		* TabDocument - SpreadsheetDocument - 
// 		* Template - SpreadsheetDocument - 
// 		* SettingsTree - ValueTree - 
// 		* PriceSetup - DocumentRef.PriceSetup, String - 
// 		* PrintObjects - ValueList - 
// 		* PrintParameters - Structure - 
// 		* QueryResult - Structure - Contains:
// 			** Products - QueryResult - 
// 			** TypesOfPrices - QueryResult - 
// 			** Header - QueryResult - 
//  
Function NewPrintParameterStructure()

	QueryResults = New Structure;
	QueryResults.Insert("Header");
	QueryResults.Insert("TypesOfPrices");
	QueryResults.Insert("Products");
		
	Parameters = New Structure;
	Parameters.Insert("UsePriceManagementSystem25", False);
	Parameters.Insert("RowNumberStart");
	Parameters.Insert("TabDocument");
	Parameters.Insert("Template");
	Parameters.Insert("SettingsTree");
	Parameters.Insert("PriceSetup");
	Parameters.Insert("PrintObjects");
	Parameters.Insert("PrintParameters");
	Parameters.Insert("QueryResult", QueryResults);
	
	Return Parameters;
	
EndFunction

// This function generates a tabular document with a printed form for setting the item prices.
//
// Returns:
//  SpreadsheetDocument - 
//
Function CreatePrintedFormForSettingProductPrices(ObjectsArray, PrintObjects, PrintParameters) Export
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_PriceSetup";
	
	Template = PrintManagement.PrintFormTemplate("Document.PriceSetup.PF_MXL_PriceSetup");
	
	TypesOfPrices = SettingPricesServer.InitializeTableOfSelectedPrices();
	SettingsTree = GetFromTempStorage(PrintParameters.SettingsTree);
	For Each TreeRow In SettingsTree.Rows Do
		If TreeRow.Print Then
			PriceLine_ = TypesOfPrices.Add();
			PriceLine_.PriceKind = TreeRow.Parameter;
			PriceLine_.AddlOrderingAttribute = TypesOfPrices.Count();
		EndIf;
	EndDo;
	
	DataForPrint = Undefined;
	If ValueIsFilled(PrintParameters.AddressDataForPrintingInTheTemporaryStorage) Then
		DataForPrint = GetFromTempStorage(PrintParameters.AddressDataForPrintingInTheTemporaryStorage);
	EndIf;

	If DataForPrint = Undefined Then

		FirstDocument = True;
		For Each PriceSetup In ObjectsArray Do
			
			If Not FirstDocument Then
				TabDocument.PutHorizontalPageBreak();
			EndIf;
			
			UsePriceManagementSystem25 = (PriceSetup.Goods.Count() = 0);
			
			FirstDocument = False;
			
			RowNumberStart = TabDocument.TableHeight + 1;
			If UsePriceManagementSystem25 Then

				QueryText =
				"SELECT
				|	TypesOfPrices.PriceKind AS PriceKind,
				|	TypesOfPrices.AddlOrderingAttribute AS AddlOrderingAttribute
				|INTO TypesOfPrices
				|FROM
				|	&TypesOfPrices AS TypesOfPrices
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	PriceSetup.Ref AS Ref,
				|	PriceSetup.Ref.Number AS Number,
				|	PriceSetup.Ref.Date AS Date,
				|	PRESENTATION(PriceSetup.Ref.EmployeeResponsible) AS EmployeeResponsiblePresentation
				|FROM
				|	Document.PriceSetup AS PriceSetup
				|WHERE
				|	PriceSetup.Ref = &PriceSetup
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.LineNumber AS LineNumber,
				|	Goods.Products AS Products,
				|	Goods.PricingVariant AS PricingVariant,
				|	Goods.PricingBatch AS PricingBatch,
				|	CASE
				|		WHEN Goods.PricingBatch.Predefined
				|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
				|		ELSE Goods.PricingBatch
				|	END AS TSOSeriesForCommunication,
				|	Goods.PricingPackage AS PricingPackage,
				|	CASE
				|		WHEN Goods.PricingPackage = Goods.Products.UnitOfMeasure
				|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
				|		ELSE Goods.PricingPackage
				|	END AS TsoPackagingForCommunication,
				|	Goods.Package AS Package,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind
				|INTO DataTable
				|FROM
				|	Document.PriceSetup.Goods2_5 AS Goods
				|WHERE
				|	Goods.Ref = &PriceSetup
				|	AND Goods.PriceKind IN
				|			(SELECT
				|				TypesOfPrices.PriceKind
				|			FROM
				|				TypesOfPrices AS TypesOfPrices)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.LineNumber AS LineNumber,
				|	Goods.Products AS Products,
				|	Goods.PricingVariant AS PricingVariant,
				|	Goods.PricingBatch AS PricingBatch,
				|	Goods.TSOSeriesForCommunication AS TSOSeriesForCommunication,
				|	Goods.PricingPackage AS PricingPackage,
				|	Goods.TsoPackagingForCommunication AS TsoPackagingForCommunication,
				|	Goods.Package AS Package,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind,
				|	CASE
				|		WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|			THEN ItemPricesCrossSectionOfTheLatest.Price
				|		ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|	END AS EffectivePrice,
				|	CAST(CASE
				|			WHEN ItemPricesCrossSectionOfTheLatest.Price <> 0
				|				THEN 100 * (Goods.Price - CASE
				|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|							THEN ItemPricesCrossSectionOfTheLatest.Price
				|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|					END) / CASE
				|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|							THEN ItemPricesCrossSectionOfTheLatest.Price
				|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|					END
				|			ELSE 0
				|		END AS NUMBER(15, 2)) AS ChangePercentage
				|INTO Goods
				|FROM
				|	DataTable AS Goods
				|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(
				|				&SliceDate,
				|				(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
				|					(SELECT
				|						T.Products,
				|						T.PricingVariant,
				|						T.TSOSeriesForCommunication,
				|						T.TsoPackagingForCommunication,
				|						T.PriceKind
				|					FROM
				|						DataTable AS T)) AS ItemPricesCrossSectionOfTheLatest
				|		ON Goods.Products = ItemPricesCrossSectionOfTheLatest.Products
				|			AND Goods.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
				|			AND Goods.TSOSeriesForCommunication = ItemPricesCrossSectionOfTheLatest.PricingBatch
				|			AND Goods.TsoPackagingForCommunication = ItemPricesCrossSectionOfTheLatest.PricingPackage
				|			AND Goods.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TypesOfPrices.PriceKind AS PriceKind
				|FROM
				|	TypesOfPrices AS TypesOfPrices
				|WHERE
				|	TypesOfPrices.PriceKind IN
				|			(SELECT DISTINCT
				|				Goods.PriceKind
				|			FROM
				|				Goods AS Goods
				|			WHERE
				|				(Goods.ChangePercentage <> 0
				|					OR &All))
				|
				|ORDER BY
				|	TypesOfPrices.AddlOrderingAttribute
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.Products AS Products,
				|	Goods.PricingVariant AS PricingVariant,
				|	Goods.PricingBatch AS PricingBatch,
				|	Goods.PricingPackage AS PricingPackage,
				|	Goods.Products.DescriptionFull AS FullNameOfProduct_,
				|	PRESENTATION(Goods.PricingVariant) AS FullNameOfCharacteristic,
				|	Goods.Products.Code AS Code,
				|	Goods.Products.SKU AS SKU,
				|	Goods.Package AS Package,
				|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind,
				|	ISNULL(Goods.EffectivePrice, 0) AS OldPrice,
				|	Goods.ChangePercentage AS ChangePercentage
				|FROM
				|	Goods AS Goods
				|WHERE
				|	(Goods.ChangePercentage <> 0
				|			OR &All)
				|
				|ORDER BY
				|	Goods.LineNumber
				|TOTALS BY
				|	Products,
				|	PricingVariant,
				|	PricingBatch,
				|	PricingPackage";
			
			Else
					
				QueryText =
				"SELECT
				|	TypesOfPrices.PriceKind AS PriceKind,
				|	TypesOfPrices.AddlOrderingAttribute AS AddlOrderingAttribute
				|INTO TypesOfPrices
				|FROM
				|	&TypesOfPrices AS TypesOfPrices
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	PriceSetup.Ref AS Ref,
				|	PriceSetup.Ref.Number AS Number,
				|	PriceSetup.Ref.Date AS Date,
				|	PRESENTATION(PriceSetup.Ref.EmployeeResponsible) AS EmployeeResponsiblePresentation
				|FROM
				|	Document.PriceSetup AS PriceSetup
				|WHERE
				|	PriceSetup.Ref = &PriceSetup
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.LineNumber AS LineNumber,
				|	Goods.Products AS Products,
				|	Goods.Characteristic AS Characteristic,
				|	Goods.Package AS Package,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind
				|INTO DataTable
				|FROM
				|	Document.PriceSetup.Goods AS Goods
				|WHERE
				|	Goods.Ref = &PriceSetup
				|	AND Goods.PriceKind IN
				|			(SELECT
				|				TypesOfPrices.PriceKind
				|			FROM
				|				TypesOfPrices AS TypesOfPrices)
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.LineNumber AS LineNumber,
				|	Goods.Products AS Products,
				|	Goods.Characteristic AS Characteristic,
				|	Goods.Package AS Package,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind,
				|	CASE
				|		WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|			THEN ItemPricesCrossSectionOfTheLatest.Price
				|		ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|	END AS EffectivePrice,
				|	CAST(CASE
				|			WHEN ItemPricesCrossSectionOfTheLatest.Price <> 0
				|				THEN 100 * (Goods.Price - CASE
				|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|							THEN ItemPricesCrossSectionOfTheLatest.Price
				|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|					END) / CASE
				|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
				|							THEN ItemPricesCrossSectionOfTheLatest.Price
				|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
				|					END
				|			ELSE 0
				|		END AS NUMBER(15, 2)) AS ChangePercentage
				|INTO Goods
				|FROM
				|	DataTable AS Goods
				|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
				|				&SliceDate,
				|				(Products, Characteristic, PriceKind) IN
				|					(SELECT
				|						T.Products,
				|						T.Characteristic,
				|						T.PriceKind
				|					FROM
				|						DataTable AS T)) AS ItemPricesCrossSectionOfTheLatest
				|		ON Goods.Products = ItemPricesCrossSectionOfTheLatest.Products
				|			AND Goods.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
				|			AND Goods.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
				|WHERE
				|	CASE
				|			WHEN Goods.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
				|					AND Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
				|				THEN FALSE
				|			ELSE TRUE
				|		END
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	TypesOfPrices.PriceKind AS PriceKind
				|FROM
				|	TypesOfPrices AS TypesOfPrices
				|WHERE
				|	TypesOfPrices.PriceKind IN
				|			(SELECT DISTINCT
				|				Goods.PriceKind
				|			FROM
				|				Goods AS Goods
				|			WHERE
				|				(Goods.ChangePercentage <> 0
				|					OR &All))
				|
				|ORDER BY
				|	TypesOfPrices.AddlOrderingAttribute
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	Goods.Products AS Products,
				|	Goods.Characteristic AS Characteristic,
				|	Goods.Products.DescriptionFull AS FullNameOfProduct_,
				|	Goods.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
				|	Goods.Products.Code AS Code,
				|	Goods.Products.SKU AS SKU,
				|	Goods.Package AS Package,
				|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
				|	Goods.Price AS Price,
				|	Goods.PriceKind AS PriceKind,
				|	ISNULL(Goods.EffectivePrice, 0) AS OldPrice,
				|	Goods.ChangePercentage AS ChangePercentage
				|FROM
				|	Goods AS Goods
				|WHERE
				|	(Goods.ChangePercentage <> 0
				|			OR &All)
				|
				|ORDER BY
				|	Goods.LineNumber
				|TOTALS BY
				|	Products,
				|	Characteristic";

			EndIf;
			
			Query = New Query();
			Query.Text = QueryText;
			Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"ItemPricesCrossSectionOfTheLatest.Package",
					"ItemPricesCrossSectionOfTheLatest.Products"));
			Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor3",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"Goods.Package",
					"Goods.Products"));
			Query.SetParameter("PriceSetup", PriceSetup);
			Query.SetParameter("SliceDate",                PriceSetup.Date - 1);
			Query.SetParameter("TypesOfPrices",                  TypesOfPrices);
			Query.SetParameter("All",                      Not PrintParameters.PrintOnlyChangedPrices);
			QueryResult = Query.ExecuteBatch();
			
			Parameters = NewPrintParameterStructure();
			
			Parameters.RowNumberStart             = RowNumberStart;
			Parameters.TabDocument                   = TabDocument;
			Parameters.Template                         = Template;
			Parameters.SettingsTree                = SettingsTree;
			Parameters.PriceSetup      = PriceSetup;
			Parameters.PrintObjects                 = PrintObjects;
			Parameters.PrintParameters               = PrintParameters;
			
			Parameters.QueryResult.Header        = QueryResult[1];
			Parameters.QueryResult.TypesOfPrices      = QueryResult[4];
			Parameters.QueryResult.Products = QueryResult[5];
			Parameters.UsePriceManagementSystem25 = UsePriceManagementSystem25;
			
			Header = Parameters.QueryResult.Header.Select();
			Header.Next();
			
			If Parameters.PrintParameters.DisplayHeader Then
				TemplateArea = Parameters.Template.GetArea("Title");
				BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
					Parameters.TabDocument, Parameters.Template, TemplateArea, Header.Ref);
				TemplateArea.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
					Header, NStr("vi = 'Đặt bảng giá';
								|ru = 'Установка цен номенклатуры';
								|en = 'Price setup'; fa = 'تنظیم قیمت';
								|it = 'Impostazione dei prezzi degli articoli';
								|pl = 'Ustawianie cen towarów';
								|tr = 'Ürün fiyatlarını belirleme'", Common.DefaultLanguageCode()));
				Parameters.TabDocument.Put(TemplateArea);
			EndIf;
			
			PrintTabularPartSettingProductPrices(Parameters);
			
			If Parameters.PrintParameters.DisplayHeader Then
				TemplateArea = Parameters.Template.GetArea("Signatures");
				TemplateArea.Parameters.Fill(Header);
				Parameters.TabDocument.Put(TemplateArea);
			EndIf;
			
			PrintManagement.SetDocumentPrintArea(Parameters.TabDocument, Parameters.RowNumberStart, Parameters.PrintObjects, Parameters.PriceSetup);
			
		EndDo;
		
	Else
		
		If DataForPrint.Property("UsePriceManagementSystem25")
			And TypeOf(DataForPrint.UsePriceManagementSystem25) = Type("Boolean") Then
			UsePriceManagementSystem25 = DataForPrint.UsePriceManagementSystem25;
		ElsIf DataForPrint.Property("ValidPriceDate")
			And TypeOf(DataForPrint.UsePriceManagementSystem25) = Type("Date") Then
			
			UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(
				DataForPrint.ValidPriceDate + 1);
			
		Else
			UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
		EndIf;
		
		TMCommonUse.NumberValueTable(DataForPrint.Goods, "LineNumber");
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		If UsePriceManagementSystem25 Then

			QueryText =
			"SELECT
			|	TypesOfPrices.PriceKind AS PriceKind,
			|	TypesOfPrices.AddlOrderingAttribute AS AddlOrderingAttribute
			|INTO TypesOfPrices
			|FROM
			|	&TypesOfPrices AS TypesOfPrices
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	UNDEFINED AS Ref,
			|	UNDEFINED AS Number,
			|	UNDEFINED AS Date,
			|	UNDEFINED AS EmployeeResponsiblePresentation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	CAST(Goods.Products AS Catalog.Products) AS Products,
			|	Goods.PricingVariant AS PricingVariant,
			|	Goods.PricingBatch AS PricingBatch,
			|	Goods.TSOSeriesForCommunication AS TSOSeriesForCommunication,
			|	Goods.PricingPackage AS PricingPackage,
			|	Goods.TsoPackagingForCommunication AS TsoPackagingForCommunication,
			|	Goods.Package AS Package,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind
			|INTO DataTable
			|FROM
			|	&Goods AS Goods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	Goods.Products AS Products,
			|	Goods.PricingVariant AS PricingVariant,
			|	Goods.PricingBatch AS PricingBatch,
			|	Goods.PricingPackage AS PricingPackage,
			|	Goods.Package AS Package,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind,
			|	CASE
			|		WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|			THEN ItemPricesCrossSectionOfTheLatest.Price
			|		ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|	END AS EffectivePrice,
			|	CAST(CASE
			|			WHEN ItemPricesCrossSectionOfTheLatest.Price <> 0
			|				THEN 100 * (Goods.Price - CASE
			|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|							THEN ItemPricesCrossSectionOfTheLatest.Price
			|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|					END) / CASE
			|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|							THEN ItemPricesCrossSectionOfTheLatest.Price
			|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|					END
			|			ELSE 0
			|		END AS NUMBER(15, 2)) AS ChangePercentage
			|INTO Goods
			|FROM
			|	DataTable AS Goods
			|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(
			|				&SliceDate,
			|				(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
			|					(SELECT
			|						T.Products,
			|						T.PricingVariant,
			|						T.TSOSeriesForCommunication,
			|						T.TsoPackagingForCommunication,
			|						T.PriceKind
			|					FROM
			|						DataTable AS T
			|					WHERE
			|						T.PriceKind IN
			|							(SELECT
			|								TypesOfPrices.PriceKind
			|							FROM
			|								TypesOfPrices AS TypesOfPrices))) AS ItemPricesCrossSectionOfTheLatest
			|		ON Goods.Products = ItemPricesCrossSectionOfTheLatest.Products
			|			AND Goods.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
			|			AND Goods.TSOSeriesForCommunication = ItemPricesCrossSectionOfTheLatest.PricingBatch
			|			AND Goods.TsoPackagingForCommunication = ItemPricesCrossSectionOfTheLatest.PricingPackage
			|			AND Goods.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
			|WHERE
			|	Goods.PriceKind IN
			|			(SELECT
			|				TypesOfPrices.PriceKind
			|			FROM
			|				TypesOfPrices AS TypesOfPrices)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TypesOfPrices.PriceKind AS PriceKind
			|FROM
			|	TypesOfPrices AS TypesOfPrices
			|WHERE
			|	TypesOfPrices.PriceKind IN
			|			(SELECT DISTINCT
			|				Goods.PriceKind
			|			FROM
			|				Goods AS Goods
			|			WHERE
			|				(Goods.ChangePercentage <> 0
			|					OR &All))
			|
			|ORDER BY
			|	TypesOfPrices.AddlOrderingAttribute
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.Products AS Products,
			|	Goods.PricingVariant AS PricingVariant,
			|	Goods.PricingBatch AS PricingBatch,
			|	Goods.PricingPackage AS PricingPackage,
			|	Goods.Products.DescriptionFull AS FullNameOfProduct_,
			|	PRESENTATION(Goods.PricingVariant) AS FullNameOfCharacteristic,
			|	Goods.Products.Code AS Code,
			|	Goods.Products.SKU AS SKU,
			|	Goods.Package AS Package,
			|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind,
			|	ISNULL(Goods.EffectivePrice, 0) AS OldPrice,
			|	Goods.ChangePercentage AS ChangePercentage
			|FROM
			|	Goods AS Goods
			|WHERE
			|	(Goods.ChangePercentage <> 0
			|			OR &All)
			|
			|ORDER BY
			|	Goods.LineNumber
			|TOTALS BY
			|	Products,
			|	PricingVariant,
			|	PricingBatch,
			|	PricingPackage";
		
		Else
			
			QueryText =
			"SELECT
			|	TypesOfPrices.PriceKind AS PriceKind,
			|	TypesOfPrices.AddlOrderingAttribute AS AddlOrderingAttribute
			|INTO TypesOfPrices
			|FROM
			|	&TypesOfPrices AS TypesOfPrices
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	UNDEFINED AS Ref,
			|	UNDEFINED AS Number,
			|	UNDEFINED AS Date,
			|	UNDEFINED AS EmployeeResponsiblePresentation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	CAST(Goods.Products AS Catalog.Products) AS Products,
			|	CAST(Goods.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
			|	Goods.Package AS Package,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind
			|INTO DataTable
			|FROM
			|	&Goods AS Goods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.LineNumber AS LineNumber,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Package AS Package,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind,
			|	CASE
			|		WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|			THEN ItemPricesCrossSectionOfTheLatest.Price
			|		ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|	END AS EffectivePrice,
			|	CAST(CASE
			|			WHEN ItemPricesCrossSectionOfTheLatest.Price <> 0
			|				THEN 100 * (Goods.Price - CASE
			|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|							THEN ItemPricesCrossSectionOfTheLatest.Price
			|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|					END) / CASE
			|						WHEN ItemPricesCrossSectionOfTheLatest.Package = Goods.Package
			|							THEN ItemPricesCrossSectionOfTheLatest.Price
			|						ELSE ItemPricesCrossSectionOfTheLatest.Price / ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(&QueryTextPackagingFactor3, 1)
			|					END
			|			ELSE 0
			|		END AS NUMBER(15, 2)) AS ChangePercentage
			|INTO Goods
			|FROM
			|	DataTable AS Goods
			|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
			|				&SliceDate,
			|				(Products, Characteristic, PriceKind) IN
			|					(SELECT
			|						T.Products,
			|						T.Characteristic,
			|						T.PriceKind
			|					FROM
			|						DataTable AS T
			|					WHERE
			|						T.PriceKind IN
			|							(SELECT
			|								TypesOfPrices.PriceKind
			|							FROM
			|								TypesOfPrices AS TypesOfPrices))) AS ItemPricesCrossSectionOfTheLatest
			|		ON Goods.Products = ItemPricesCrossSectionOfTheLatest.Products
			|			AND Goods.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
			|			AND Goods.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
			|WHERE
			|	Goods.PriceKind IN
			|			(SELECT
			|				TypesOfPrices.PriceKind
			|			FROM
			|				TypesOfPrices AS TypesOfPrices)
			|	AND CASE
			|			WHEN Goods.Products.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
			|					AND Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|				THEN FALSE
			|			ELSE TRUE
			|		END
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TypesOfPrices.PriceKind AS PriceKind
			|FROM
			|	TypesOfPrices AS TypesOfPrices
			|WHERE
			|	TypesOfPrices.PriceKind IN
			|			(SELECT DISTINCT
			|				Goods.PriceKind
			|			FROM
			|				Goods AS Goods
			|			WHERE
			|				(Goods.ChangePercentage <> 0
			|					OR &All))
			|
			|ORDER BY
			|	TypesOfPrices.AddlOrderingAttribute
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Products.DescriptionFull AS FullNameOfProduct_,
			|	Goods.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
			|	Goods.Products.Code AS Code,
			|	Goods.Products.SKU AS SKU,
			|	Goods.Package AS Package,
			|	Goods.Products.UnitOfMeasure AS UnitOfMeasure,
			|	Goods.Price AS Price,
			|	Goods.PriceKind AS PriceKind,
			|	ISNULL(Goods.EffectivePrice, 0) AS OldPrice,
			|	Goods.ChangePercentage AS ChangePercentage
			|FROM
			|	Goods AS Goods
			|WHERE
			|	(Goods.ChangePercentage <> 0
			|			OR &All)
			|
			|ORDER BY
			|	Goods.LineNumber
			|TOTALS BY
			|	Products,
			|	Characteristic";

		EndIf;
		
		Query = New Query();
		Query.Text = QueryText;
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ItemPricesCrossSectionOfTheLatest.Package",
				"ItemPricesCrossSectionOfTheLatest.Products"));
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor3",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"Goods.Package",
					"Goods.Products"));
		Query.SetParameter("SliceDate",                DataForPrint.ValidPriceDate);
		Query.SetParameter("TypesOfPrices",                  TypesOfPrices);
		Query.SetParameter("Goods",                   DataForPrint.Goods);
		Query.SetParameter("All",                      Not PrintParameters.PrintOnlyChangedPrices);
		QueryResult = Query.ExecuteBatch();
		
		Parameters = NewPrintParameterStructure();
		
		Parameters.RowNumberStart             = RowNumberStart;
		Parameters.TabDocument                   = TabDocument;
		Parameters.Template                         = Template;
		Parameters.SettingsTree                = SettingsTree;
		Parameters.PriceSetup      = PriceSetup;
		Parameters.PrintObjects                 = PrintObjects;
		Parameters.PrintParameters               = PrintParameters;
		Parameters.UsePriceManagementSystem25 = UsePriceManagementSystem25;
		
		Parameters.QueryResult.Header        = QueryResult[1];
		Parameters.QueryResult.TypesOfPrices      = QueryResult[4];
		Parameters.QueryResult.Products = QueryResult[5];
		
		If PriceSetup = Undefined Then
			Parameters.PriceSetup = "PrintObjectsNotSpecified";
		EndIf;
		
		Header = Parameters.QueryResult.Header.Select();
		Header.Next();
		
		If Parameters.PrintParameters.DisplayHeader Then
			TemplateArea = Parameters.Template.GetArea("Title");
			TemplateArea.Parameters.TitleText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thay đổi đơn giá mặt hàng trong %1';
					|ru = 'Изменение цен номенклатуры за %1';
					|en = 'Change item prices for %1'; fa = 'Change item prices for %1';
					|it = 'Cambiamento dei prezzo degli articoli nel %1';
					|pl = 'Zmiana cen nomenklatury za %1';
					|tr = '%1 için ürün fiyatı değişikliği'", Common.DefaultLanguageCode()),
				Format(DataForPrint.ValidPriceDate, "DLF=D"));
			Parameters.TabDocument.Put(TemplateArea);
		EndIf;
		
		PrintTabularPartSettingProductPrices(Parameters);
		
		PrintManagement.SetDocumentPrintArea(Parameters.TabDocument, Parameters.RowNumberStart, Parameters.PrintObjects, Parameters.PriceSetup);
		
	EndIf;
	
	Return TabDocument;
	
EndFunction

// The function puts the necessary data in the structure. The structure is placed in temporary storage.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef.PriceSetup - Documents
// 
// Returns:
//  String - the address of the data structure in the temporary storage.
Function LabelPrintingData(DocumentsArray) Export

	PrintParameters = New Structure();
	PrintParameters.Insert("PrintOption", "PrintLabels");
	PrintParameters.Insert("FillingVariant", "FillInTheNumberOfLabelsForStockBalances");

	Return DataForPrintingLabelsOrPriceTags(DocumentsArray, PrintParameters);
	
EndFunction

// The function puts the necessary data in the structure. The structure is placed in temporary storage.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef.PriceSetup - Documents
// 
// Returns:
//  String -the address of the data structure in the temporary storage.
Function DataForPrintingPriceTags(DocumentsArray) Export

	PrintParameters = New Structure();
	PrintParameters.Insert("PrintOption", "PrintingPriceTags");
	PrintParameters.Insert("FillingVariant", "FillInTheNumberOfPriceTagsForTheDocument");

	Return DataForPrintingLabelsOrPriceTags(DocumentsArray, PrintParameters);
	
EndFunction

// The function puts the necessary data in the structure. The structure is placed in temporary storage.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef.PriceSetup - Documents
//  PrintParameters - Structure - print options:
// * PrintOption - String -
// * FillingVariant - String -
// 
// Returns:
//  String -- the address of the data structure in the temporary storage.
Function DataForPrintingLabelsOrPriceTags(DocumentsArray, PrintParameters)
	
	Query = New Query;

	Query.Text = 
	"SELECT
	|	SettingPricesForProductProductRange.Products AS Products,
	|	SettingPricesForProductProductRange.PricingVariant AS PricingVariant,
	|	SettingPricesForProductProductRange.PricingPackage AS Package,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	MIN(SettingPricesForProductProductRange.LineNumber) AS Order,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END AS ItemVariantsOwner
	|INTO PricesOfNomenclaturePrev
	|FROM
	|	Document.PriceSetup.Goods2_5 AS SettingPricesForProductProductRange
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON SettingPricesForProductProductRange.PricingBatch = ItemsBatches.ItemsBatchForPricing
	|		AND SettingPricesForProductProductRange.PricingBatch <> VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		LEFT JOIN Catalog.Products AS CatProducts_
	|		ON SettingPricesForProductProductRange.Products = CatProducts_.Ref
	|WHERE
	|	SettingPricesForProductProductRange.Ref IN (&DocumentsArray)
	|	AND CASE
	|		WHEN SettingPricesForProductProductRange.Products.UseVariants IN
	|		(VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|			VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|		AND SettingPricesForProductProductRange.PricingVariant = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|GROUP BY
	|	SettingPricesForProductProductRange.Products,
	|	SettingPricesForProductProductRange.PricingPackage,
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)),
	|	SettingPricesForProductProductRange.PricingVariant,
	|	CASE
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|			THEN CatProducts_.Ref
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|			THEN CatProducts_.ProductKind
	|		WHEN
	|			CatProducts_.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|			THEN CatProducts_.ItemVariantsOwner
	|		ELSE UNDEFINED
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemData_3.Products AS Products,
	|	ItemData_3.Characteristic AS Characteristic,
	|	ItemData_3.Package,
	|	ItemData_3.Series,
	|	MIN(ItemData_3.Order) AS Order,
	|	SUM(1) AS Count
	|FROM
	|	(SELECT
	|		PricesOfNomenclaturePrev.Products,
	|		ISNULL(ItemsCharacteristics.Ref, ISNULL(ItemsCharacteristics1.Ref,
	|			VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS Characteristic,
	|		PricesOfNomenclaturePrev.Package,
	|		PricesOfNomenclaturePrev.Series,
	|		PricesOfNomenclaturePrev.Order
	|	FROM
	|		PricesOfNomenclaturePrev AS PricesOfNomenclaturePrev
	|			LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|			ON PricesOfNomenclaturePrev.PricingVariant <> VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|			AND PricesOfNomenclaturePrev.PricingVariant = ItemsCharacteristics.ItemsCharacteristicForPricing
	|			LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|			ON PricesOfNomenclaturePrev.PricingVariant = VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|			AND PricesOfNomenclaturePrev.ItemVariantsOwner = ItemsCharacteristics1.Owner
	|
	|	UNION ALL
	|
	|	SELECT
	|		SettingPricesForProductProductRange.Products,
	|		SettingPricesForProductProductRange.Characteristic,
	|		SettingPricesForProductProductRange.Package,
	|		VALUE(Catalog.ItemsBatches.EmptyRef),
	|		SettingPricesForProductProductRange.LineNumber
	|	FROM
	|		Document.PriceSetup.Goods AS SettingPricesForProductProductRange
	|	WHERE
	|		SettingPricesForProductProductRange.Ref IN (&DocumentsArray)
	|		AND CASE
	|			WHEN SettingPricesForProductProductRange.Products.UseVariants IN
	|			(VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			AND SettingPricesForProductProductRange.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				THEN FALSE
	|			ELSE TRUE
	|		END) AS ItemData_3
	|GROUP BY
	|	ItemData_3.Products,
	|	ItemData_3.Characteristic,
	|	ItemData_3.Package,
	|	ItemData_3.Series
	|
	|ORDER BY
	|	Order,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PriceSetup.PriceKind AS PriceKind
	|FROM
	|	Document.PriceSetup.TypesOfPrices AS PriceSetup
	|WHERE
	|	PriceSetup.Ref IN (&DocumentsArray)";
		
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableDocumentDetails = ResultsArray[2].Unload();
	ArrayOfPriceTypes = TableDocumentDetails.UnloadColumn(0);
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",       Undefined);
	StructureOfActions.Insert("FillInPriceView",     ?(ArrayOfPriceTypes.Count() = 1, ArrayOfPriceTypes[0], Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", False);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", PrintParameters.PrintOption);
	StructureOfActions.Insert(PrintParameters.FillingVariant);
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", ResultsArray[1].Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date", TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray));
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
