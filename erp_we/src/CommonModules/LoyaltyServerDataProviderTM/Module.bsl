///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Checks the usage of the loyalty server library
//
// Parameters:
//  Response - HTTPServiceResponse - loyalty server response
//  Result - Boolean - True if the Loyalty Server is used, False if not used.
//
Procedure UseLoyaltyServer(Response, Result) Export
	
	UseLoyaltyServer = Constants.UseLoyaltyServerDataProvider.Get();
	If Not UseLoyaltyServer Then
		Response.StatusCode = 423;
	EndIf;
	
	Result = UseLoyaltyServer;
	
EndProcedure

// Fills in the list of managed discounts
//
// Parameters:
//  Result - See LoyaltyServiceOverridable.FillInTableOfManagedDiscounts.Result
//  CalculationParameters - See LoyaltyServiceOverridable.FillInTableOfManagedDiscounts.CalculationParameters
//
Procedure FillInTableOfManagedDiscounts(Result, Val CalculationParameters) Export
	
	SetPrivilegedMode(True);
	
	AdvancedFilter = FillInTableOfManagedDiscountsCalculationParameters(CalculationParameters);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup AS DiscountMarkup,
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup.DiscountMarkupValue AS DiscountValue,
		|	""Automatic"" AS DiscountType,
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup.Presentation AS Presentation,
		|	""to1 Document"" AS Scope
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&DiscountsOnDate, DiscountMarkup.Managed) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
		|WHERE
		|	TheEffectOfDiscountsMarkupsASliceOfTheLast.Status = &ValidStatus
		|";
	
	Query.Parameters.Insert("Store", AdvancedFilter.Store);
	
	Query.SetParameter("DiscountsOnDate", CurrentSessionDate());
	Query.SetParameter("ValidStatus", Enums.DiscountValidityStatuses.Valid);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		NewRow = Result.Add();
		FillPropertyValues(NewRow, Selection);
		If CommonClientServer.HasAttributeOrObjectProperty(NewRow, "DiscountID") Then
			NewRow.DiscountID = String(Selection.DiscountMarkup.UUID());
		EndIf;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Fills in the bonus program on the buyer's discount card
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - 
//                    loyalty card that will be used to fill in bonus data
//  BonusProgram - DefinedType.BonusProgramLoyaltyServer - Loyalty Program
//
Procedure FillOutBonusProgramOnDiscountCard(DiscountCard, BonusProgram) Export
	
	DetailsOfBonusProgram = BonusPointsServer.LoyaltyCardBonusProgram(DiscountCard);
	BonusProgram = DetailsOfBonusProgram.LoyaltyProgram;
	
EndProcedure

// Fills in the structure of the Loyalty Server response with data on the Balance of bonus points
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - 
//                    loyalty card that will be used to fill in bonus data
//  ResponseStructure - See LoyaltyServiceOverridable.FillInBonusDetails.ResponseStructure
//
Procedure FillInBonusDetails(DiscountCard, ResponseStructure) Export
	
	DetailsOfBonusProgram = BonusPointsServer.LoyaltyCardBonusProgram(DiscountCard);

	BalanceBonusPoints = GetCustomerBonusPoints(DetailsOfBonusProgram.LoyaltyProgram, DetailsOfBonusProgram.Partner);
	BonusPointsReserve = LoyaltyService.GetBonusPointsReserve(DiscountCard);
	
	If ValueIsFilled(DetailsOfBonusProgram.MaximumSharePayableByPoints) Then
		ResponseStructure.PaymentPercent = DetailsOfBonusProgram.MaximumSharePayableByPoints;
	EndIf;
	
	// We check the situation when there may be more bonus points in the reserve than on the Balance,
	// in this case we return 0
	If BonusPointsReserve > BalanceBonusPoints Then
		ResponseStructure.BonusCount = 0;
	Else
		ResponseStructure.BonusCount = BalanceBonusPoints - BonusPointsReserve;
	EndIf
	
EndProcedure

// Searches for the client's card based on parameters received via the http service
//
// Parameters:
//  Data - Structure - a structure containing client parameters:
//    * IdOfClientSCard - String - loyalty card code
//    * Client - String - Full name of the cardholder
//    * EMAddress - String - e-mail address of the cardholder
//    * PhoneNumber - String - phone number of the cardholder
//  Result - DefinedType.LoyaltyCardOfLoyaltyServer, Undefined - customer's discount card
//
Procedure FindCustomerCard(Data, Result = Undefined) Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED TOP 1
		|	NestedQuery.Ref AS Ref,
		|	NestedQuery.Priority AS Priority
		|FROM
		|	(SELECT DISTINCT
		|		LoyaltyCards.Ref AS Ref,
		|		1 AS Priority
		|	FROM
		|		Catalog.LoyaltyCards AS LoyaltyCards
		|	WHERE
		|		NOT LoyaltyCards.DeletionMark
		|		AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
		|		AND &IdOfClientSCard <> """"
		|		AND (&CardKind = VALUE(Catalog.LoyaltyCardKinds.EmptyRef) OR LoyaltyCards.Owner = &CardKind)
		|		AND &IdOfClientSCard IN (LoyaltyCards.Barcode, LoyaltyCards.MagneticCode)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		LoyaltyCards.Ref,
		|		2
		|	FROM
		|		Catalog.LoyaltyCards AS LoyaltyCards
		|			INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
		|			ON LoyaltyCards.Partner = PartnersContactInformation.Ref
		|				AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
		|				AND PartnersContactInformation.PhoneNumber = &PhoneNumber
		|				AND &PhoneNumber <> """"
		|				AND PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Phone)
		|				AND NOT PartnersContactInformation.Ref.DeletionMark
		|				AND (&CardKind = VALUE(Catalog.LoyaltyCardKinds.EmptyRef) OR LoyaltyCards.Owner = &CardKind)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		LoyaltyCards.Ref,
		|		3
		|	FROM
		|		Catalog.LoyaltyCards AS LoyaltyCards
		|			INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
		|			ON LoyaltyCards.Partner = PartnersContactInformation.Ref
		|				AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
		|				AND PartnersContactInformation.EMAddress = &EMAddress
		|				AND &EMAddress <> """"
		|				AND NOT PartnersContactInformation.Ref.DeletionMark
		|				AND (&CardKind = VALUE(Catalog.LoyaltyCardKinds.EmptyRef) OR LoyaltyCards.Owner = &CardKind)
		|				AND PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Email)) AS NestedQuery
		|
		|ORDER BY
		|	Priority";
	
	CardKind = Catalogs.LoyaltyCardKinds.EmptyRef();
	If Data.Property("MapViewGUIDE") And ValueIsFilled(Data.MapViewGUIDE) Then
		CardKind = Catalogs.LoyaltyCardKinds.GetRef(New UUID(Data.MapViewGUIDE));
	EndIf;
	
	PhoneSearchBar = PrepareSearchStringByPhoneNumber(Data.PhoneNumber);
	If ValueIsFilled(PhoneSearchBar) And Left(PhoneSearchBar, 1) = "%" Then
		Query.Text = StrReplace(Query.Text, "PhoneNumber = &PhoneNumber",
			"PhoneNumber LIKE &PhoneNumber");
	EndIf;
	
	Query.SetParameter("IdOfClientSCard", Data.IdOfClientSCard);
	Query.SetParameter("CardKind", CardKind);
	Query.SetParameter("PhoneNumber", PhoneSearchBar);
	Query.SetParameter("EMAddress", Data.EMAddress);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
EndProcedure

// Creates customer cards
//
// Parameters:
//  CardData - See LoyaltyServiceOverridable.CreateCustomerCard.CardData
//  Result - DefinedType.LoyaltyCardOfLoyaltyServer, Undefined - contains the value
//				in which the link to the created loyalty card will be stored.
//  OtherClient - CatalogRef.Counterparties - counterparty with a matching e-mail, but a different phone number
//  ErrorDescription - String - returned value
//
Procedure CreateCustomerCard(CardData, Result = Undefined, OtherClient = Undefined, ErrorDescription = "") Export
	
	SetPrivilegedMode(True);

	LoyaltyCardKind = GetTypeOfLoyaltyCard(CardData.MapViewGUIDE);
	
	If Not CheckCardDetails(CardData.IdOfClientSCard, LoyaltyCardKind) Then
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã nhập sai số thẻ (%1)';
				|ru = 'Номер карты (%1) введен неверно';
				|en = 'Card number (%1) is incorrect'; fa = 'Card number (%1) is incorrect';
				|it = 'Номер карты (%1) введен неверно';
				|pl = 'Card number (%1) is incorrect';
				|tr = 'Kart numarası (%1) yanlış girildi'"),
			CardData.IdOfClientSCard);
		ErrorDescription = LongDesc;
		WriteLogEvent("LoyaltyServer.CreateCustomerCard",
			EventLogLevel.Error,,,
			LongDesc);
		Return;
	EndIf;
	
	LoyaltyCard = Catalogs.LoyaltyCards.EmptyRef();
	
	If LoyaltyCardKind <> Undefined Then
		Personalized = Common.ObjectAttributeValue(LoyaltyCardKind, "Personalized");
		Cardholder = Catalogs.Counterparties.EmptyRef();
		If Personalized Then
			GetResult1 = GetCardholder(CardData);
			If ValueIsFilled(GetResult1.Cardholder) Then
				If GetResult1.StatusOfReceipt = 3 Then
					OtherClient = GetResult1.Cardholder;
				Else
					Cardholder = GetResult1.Cardholder;
				EndIf;
			EndIf;
		EndIf;
	
		If ValueIsFilled(Cardholder) Or Not Personalized Then
		
			BeginTransaction();
			
			Try
				
				MapDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
				MapDataStructure.Barcode 			= CardData.IdOfClientSCard;
				MapDataStructure.MagneticCode 		= CardData.IdOfClientSCard;
				MapDataStructure.AccessGroup		= Constants.PartnerSAccessGroupAtAutoCreation.Get();
				MapDataStructure.CardKind			= LoyaltyCardKind;
				MapDataStructure.Partner			= Cardholder;
				
				LoyaltyCard = LoyaltyCardsServer.RegisterLoyaltyCard(MapDataStructure);
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorInfo = ErrorInfo();
				ErrorDescriptionTemplate = NStr(
					"vi = 'Lỗi tạo thẻ (%1) do nguyên nhân:
					|""%2""';
					|ru = 'Ошибка создания карты (%1) по причине:
					|""%2""';
					|en = 'Error creating the card (%1). Reason:
					|""%2""'; fa = 'Error creating the card (%1). Reason:
					|""%2""';
					|it = 'Ошибка создания карты (%1) по причине:
					|""%2""';
					|pl = 'Error creating the card (%1). Reason:
					|""%2""';
					|tr = 'Harita oluşturma hatası (%1) şu nedenden dolayı:
					|""%2""'");
				LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					CardData.IdOfClientSCard,
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
				WriteLogEvent("LoyaltyServer.CreateCustomerCard",
					EventLogLevel.Error,,,
					LongDesc);
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					CardData.IdOfClientSCard,
					ErrorProcessing.ErrorDescriptionForUser(ErrorInfo));
				
			EndTry;
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	Result = LoyaltyCard;
	
EndProcedure

// Fills in the http service response structure with discount card data
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer
//  ResponseStructure - See LoyaltyServiceOverridable.FillInResponseStructureWithMapData.ResponseStructure
//  MapExists - Boolean
//
Procedure FillInResponseStructureWithMapData(DiscountCard, ResponseStructure, MapExists = False) Export 
	
	Data = GetLoyaltyCardDetails(DiscountCard);
	
	If Data = Undefined Then 
		Return;
	EndIf;
	
	ResponseStructure.CardID 			= Data.CardNumber;
	ResponseStructure.CardRef 		= XMLString(DiscountCard);
	ResponseStructure.Client 			= Data.PartnerPresentation;
	ResponseStructure.PhoneNumber		= Data.PhoneNumber;
	ResponseStructure.Email 			= Data.Email;
	ResponseStructure.ExistingCard	= MapExists;
	ResponseStructure.DateOfBirth		= Data.BirthDate;
	ResponseStructure.PaymentPercent	= Data.MaximumSharePayableByPoints;

EndProcedure

// Fills the http service response structure with client data
//
// Parameters:
//  Client - CatalogRef.Counterparties
//  ResponseStructure - See LoyaltyServiceOverridable.FillInResponseStructureWithClientData.ResponseStructure
//
Procedure FillInResponseStructureWithClientData(Client, ResponseStructure) Export
	
	Data = GetClientData(Client);
	
	If Data = Undefined Then 
		Return;
	EndIf;
	
	ResponseStructure.Client 			= Data.PartnerPresentation;
	ResponseStructure.PhoneNumber		= Data.PhoneNumber;
	ResponseStructure.Email 			= Data.Email;
	ResponseStructure.ExistingCard	= True;
	ResponseStructure.DateOfBirth		= Data.BirthDate;
	ResponseStructure.ElseClient		= True;
	
EndProcedure

// Returns data about the use of automatic discounts
//
// Parameters:
//  Result - Boolean - True, automatic discounts are used,
//						 False, automatic discounts are not used.
//
Procedure UseAutomaticDiscounts(Result) Export
	
	Result = Constants.UseDiscountsMarkupsInSales.Get();
	
EndProcedure

// Calculates automatic discounts
//
// Parameters:
//  CalculationParameters - Structure - See DeserializeCalculationParameters
//  Result - Structure - a data structure with calculated automatic discounts.
//
Procedure CalculateAutoDiscounts(CalculationParameters, Result) Export
	
	ThisIsReturn = CalculationParameters.Property("ThisIsReturn") And CalculationParameters.ThisIsReturn = True;
	If ThisIsReturn Then
		CashRegisterReceiptObject = Documents.CashRegisterReceiptReturn.CreateDocument();
	Else
		CashRegisterReceiptObject = Documents.CashRegisterReceipt.CreateDocument();
	EndIf;
	FillPropertyValues(CashRegisterReceiptObject, CalculationParameters);
	
	For Each RowGoods In CalculationParameters.Goods Do
		NewRow = CashRegisterReceiptObject.Goods.Add();
		FillPropertyValues(NewRow, RowGoods);
	EndDo;
	
	InputParameters = New Structure;
	InputParameters.Insert("RestoreManagedDiscounts", True);
	InputParameters.Insert("ApplyToObject", True);
	InputParameters.Insert("OnlyPreliminaryCalculation", False);
	If ThisIsReturn Then
		InputParameters.Insert("RestoreManagedDiscounts", False);
		InputParameters.Insert("ApplyToObject", False);
		InputParameters.Insert("OnlyPreliminaryCalculation", True);
	EndIf;
	
	ManagedDiscounts = New ValueList();
	ManagedDiscounts.LoadValues(CalculationParameters.SelectedManagedDiscounts.UnloadColumn("DiscountMarkup"));
	InputParameters.Insert("ManagedDiscounts", ManagedDiscounts);
	
	CalculationResult2 = DiscountsMarkupsServer.Calculate(CashRegisterReceiptObject, InputParameters);
	
	SerializedDiscountStructure = SerializeCalculationResult(CashRegisterReceiptObject);
	
	TableDiscountsMarkups = CalculationResult2.TableDiscountsMarkups;
	
	// Fill in the link between the discount and the product table row
	TableDiscountsMarkups.Columns.Add("RowID", New TypeDescription("String", , , New StringQualifiers(36)));
	For Each DiscountsRow In TableDiscountsMarkups Do
		If ValueIsFilled(DiscountsRow.ConnectionKey) Then // Otherwise, the row ID is not required
			DiscountItemLines = CalculationParameters.Goods.FindRows(New Structure("ConnectionKey", DiscountsRow.ConnectionKey));
			If DiscountItemLines.Count() Then
				DiscountsRow.RowID = DiscountItemLines[0].RowID;
			EndIf;
		EndIf;
	EndDo;
	
	SupplementDiscountStructureWithMarkupDiscountTable(SerializedDiscountStructure, TableDiscountsMarkups);
	
	AddMessagesToDiscountStructure(SerializedDiscountStructure, CashRegisterReceiptObject);
	
	If CashRegisterReceiptObject.BonusPoints.Count() > 0 Then
		SupplementStructureOfDiscountsWithTableOfBonuses(SerializedDiscountStructure, CalculationResult2, CashRegisterReceiptObject);
	EndIf;
	
	Result = SerializedDiscountStructure;
	
EndProcedure

// Deserializes parameters for calculating automatic discounts received in JSON format
//
// Parameters:
//  IncomingData - String - contains the string value of the request body in JSON format.
//  Result - Structure - data structure with deserialized parameters for calculating automatic discounts:
//    * InputParameters				 - Structure:
//       * OnlyPreliminaryCalculation - Boolean
//    * Goods							 - ValueTable
//    * ManagementAccountingCurrency		 - CatalogRef.Currencies
//    * User					 - Undefined
//    * CurrentDate						 - Date
//    * Date							 - Date
//    * OnlyMessagesAfterRegistration	 - Boolean
//    * Recorder						 - DocumentRef.CashRegisterReceipt
//    * Ref							 - DocumentRef.CashRegisterReceipt
//    * AmountIncludesVAT				 - Boolean
//    * DiscountsAreCalculated				 - Boolean
//    * DiscountCard					 - CatalogRef.LoyaltyCards
//    * TypeOfDiscountCard				 - Undefined
//    * Counterparty						 - Undefined
//    * DiscountPercentageOnDiscountCard	 - Number
//    * Warehouse							 - Undefined
//    * DocumentCurrency					 - Undefined
//    * PricesKind							 - CatalogRef.TypesOfPrices
//
Procedure DeserializeCalculationParameters(IncomingData, Result) Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("HasErrors", False);
	CalculationParameters.Insert("ErrorDescription", "");
	
	Try
		
		JSONReader = New JSONReader();
		JSONReader.SetString(IncomingData);
		IncomingDataInJSON = ReadJSON(JSONReader, , "CurrentDate", JSONDateFormat.ISO);
		JSONReader.Close();
		
		If CheckCorrectnessOfIncomingData(IncomingDataInJSON, CalculationParameters) Then
			
			ThisIsReturn = False;
			IncomingDataInJSON.Property("Return", ThisIsReturn);
			CalculationParameters.Insert("ThisIsReturn", ThisIsReturn);
			
			Recorder = Documents.CashRegisterReceipt.EmptyRef();
			DiscountCard = Undefined;
			GetDiscountCard(IncomingDataInJSON, "LoyaltyCardsList", DiscountCard);
			
			InputParameters = New Structure;
			InputParameters.Insert("OnlyPreliminaryCalculation", False);
			
			// Bonus Program
			If ValueIsFilled(DiscountCard) Then
				DetailsOfBonusProgram = BonusPointsServer.LoyaltyCardBonusProgram(DiscountCard);
				If ValueIsFilled(DetailsOfBonusProgram.LoyaltyProgram) Then
					InputParameters.Insert("BonusProgram", DetailsOfBonusProgram.LoyaltyProgram);
					InputParameters.Insert("ApplyToObject", True);
				EndIf;
				CalculationParameters.Insert("TypeOfDiscountCard", DetailsOfBonusProgram.LoyaltyCardKind);
				CalculationParameters.Insert("Partner", DetailsOfBonusProgram.Partner);
				CalculationParameters.Insert("DiscountPercentageOnDiscountCard", DetailsOfBonusProgram.MaximumSharePayableByPoints);
			Else
				CalculationParameters.Insert("TypeOfDiscountCard", Catalogs.LoyaltyCardKinds.EmptyRef());
				CalculationParameters.Insert("Partner", Catalogs.Partners.EmptyRef());
				CalculationParameters.Insert("DiscountPercentageOnDiscountCard", 0);
			EndIf;
			
			CalculationParameters.Insert("Goods", GetDeserializedItemTable(IncomingDataInJSON, "Goods"));
			CalculationParameters.Insert("SelectedManagedDiscounts", GetDeserializedTableOfSelectedManagedDiscounts(IncomingDataInJSON, "ControlledDiscountsList"));
			CalculationParameters.Insert("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
			CalculationParameters.Insert("User", Undefined);
			CalculationParameters.Insert("CurrentDate", IncomingDataInJSON.CurrentDate);
			CalculationParameters.Insert("Date", IncomingDataInJSON.CurrentDate);
			CalculationParameters.Insert("OnlyMessagesAfterRegistration", False);
			CalculationParameters.Insert("Recorder", Recorder);
			CalculationParameters.Insert("Ref", Recorder);
			CalculationParameters.Insert("AmountIncludesVAT", True);
			CalculationParameters.Insert("DiscountsAreCalculated", False);
			CalculationParameters.Insert("LoyaltyCard", DiscountCard);
			CalculationParameters.Insert("DocumentBorder", New Boundary(IncomingDataInJSON.CurrentDate, BoundaryType.Excluding));
			
			CalculationParameters.Insert("Warehouse", LoyaltyService.GetDeserializedReferenceValue(IncomingDataInJSON, "RetailStore", "Catalogs.Warehouses"));
			
			If ValueIsFilled(CalculationParameters.Warehouse) Then
				CalculationParameters.Insert("PriceKind", Common.ObjectAttributeValue(CalculationParameters.Warehouse, "RetailPriceType"));
				CalculationParameters.Insert("Currency", Common.ObjectAttributeValue(CalculationParameters.PriceKind, "PriceCurrency"));
			Else
				CalculationParameters.Insert("PriceKind", Catalogs.TypesOfPrices.EmptyRef());
				CalculationParameters.Insert("Currency", CalculationParameters.ManagementAccountingCurrency);
			EndIf;
			
			CalculationParameters.Insert("InputParameters", InputParameters);
			
			CalculationParameters.Insert("ReturnCardDetails", False);
			If IncomingDataInJSON.Property("GetLoyaltyCardData") Then
				CalculationParameters.ReturnCardDetails = IncomingDataInJSON.GetLoyaltyCardData;
			EndIf;
			CalculationParameters.Insert("BlockCard", "0");
			If IncomingDataInJSON.Property("BlockBonuses") Then
				CalculationParameters.BlockCard = IncomingDataInJSON.BlockBonuses;
			EndIf;
			
		EndIf;
		
	Except
		
		LongDesc = StrTemplate(NStr("vi = 'Lỗi chuyển đổi nội dung truy vấn theo ngyên nhân: %1';
									|ru = 'Ошибка преобразования тела запроса по причине: %1';
									|en = 'An error occurred when converting the request body. Reason: %1'; fa = 'An error occurred when converting the request body. Reason: %1';
									|it = 'Ошибка преобразования тела запроса по причине: %1';
									|pl = 'An error occurred when converting the request body. Reason: %1';
									|tr = 'Talep cismi dönüştürme işleminin hata nedeni: %1'"), ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		CalculationParameters.HasErrors = True;
		CalculationParameters.ErrorDescription = LongDesc;
		
		WriteLogEvent("LoyaltyServer.AutomaticCalculationOfDiscounts",
			EventLogLevel.Error,,,
			LongDesc);
		
	EndTry;
	
	Result = CalculationParameters;
	
EndProcedure

// Checks the use of the gift card payment function
//
// Parameters:
//  Result - Boolean - the variable in which the result of checking the use
//			 of the gift card payment function will be recorded.
//
Procedure CheckUseOfGiftCards(Result) Export
	
	Result = False;
	
EndProcedure

// Fills in the received structure of Attributes with the names of the Attributes of the sales document (Receipt)
//
// Parameters:
//  AttributesNames - Structure - definition in See LoyaltyService.FillInEmptyStructureNamesOfMetadataAttributes.AttributesNames:
//    * BankingDetailsNameDiscountCard - String
//    * DetailsNamePaymentTable - String
//    * PropsNameGiftCard - String
//    * PropsNameSerialNumber - String
//    * DetailsNameBonusAmount - String
//    * DetailsNameCertificateRedemptionTable - String
//    * DetailsNameCertificateRedemptionAmount - String
//
Procedure FillInNamesOfAttributesOfDataProvider(AttributesNames) Export
	
	AttributesNames.BankingDetailsNameDiscountCard = "LoyaltyCard";
	AttributesNames.DetailsNamePaymentTable = "Goods";
	AttributesNames.DetailsNameBonusAmount = "AmountOfBonusPointsToDeductionInCurrency";
	
EndProcedure

// Fills in the http service response structure with the data of the found maps
//
// Parameters:
//  MethodParameters - Structure - a structure containing map search parameters:
//    * IdOfClientSCard - String - loyalty card code
//    * PhoneNumber - String - phone number or the last part of the phone number to search for
//    * EMAddress - String - the cardholder's email address for the search
//  ResponseStructure - See LoyaltyServiceOverridable.FindLoyaltyCards.ResponseStructure
//
Procedure FindLoyaltyCards(MethodParameters, ResponseStructure) Export
	
	CustomerCard	= GetCardWithUniqueId(MethodParameters.UniqueCardId);
	Cardholder	= GetCardholderByUniqueId(MethodParameters.UniqueIdOfCardholder);
	If ValueIsFilled(CustomerCard) Then
		FindLoyaltyCardByFollowingLink(CustomerCard, ResponseStructure);
	EndIf;
	If ResponseStructure.LoyaltyCardsList.Count() = 0 And ValueIsFilled(Cardholder) Then
		FindLoyaltyCardByOwner(Cardholder, ResponseStructure);
	EndIf;
	If ResponseStructure.LoyaltyCardsList.Count() = 0
			And ValueIsFilled(MethodParameters.IdOfClientSCard) Then
		FindLoyaltyCardByCardNumber(MethodParameters.IdOfClientSCard, ResponseStructure);
	EndIf;
	If ResponseStructure.LoyaltyCardsList.Count() = 0 Then
		PhoneSearchBar = PrepareSearchStringByPhoneNumber(MethodParameters.PhoneNumber);
		If PhoneSearchBar <> "" Or MethodParameters.EMAddress <> "" Then
			FindLoyaltyCardsByContactInformation(PhoneSearchBar, MethodParameters.EMAddress, ResponseStructure);
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the http service response structure with the discount card numbers and unique identifier
//
// Parameters:
//  CustomerCard - DefinedType.LoyaltyCardOfLoyaltyServer
//  ResponseStructure - See LoyaltyServiceOverridable.FillInResponseStructureWithCardNumbers.ResponseStructure
//
Procedure FillInResponseStructureWithCardNumbers(CustomerCard, ResponseStructure) Export
	
	CardNumbers = Common.ObjectAttributesValues(CustomerCard, "Barcode,MagneticCode");
	
	ResponseStructure.CardRef = XMLString(CustomerCard);
	ResponseStructure.Barcode = CardNumbers.Barcode;
	ResponseStructure.MagneticCode = CardNumbers.MagneticCode;
	
EndProcedure

// Fills in the list of card types
//
// Parameters:
//  Result - Undefined, ValueTable - returned value
//  CalculationParameters - See LoyaltyServiceOverridable.FillInTableOfCardTypes.CalculationParameters
//
Procedure FillInTableOfCardTypes(Result, CalculationParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	CardKind = Constants.CardKindLoyaltyServer.Get();
	
	If ValueIsFilled(CardKind) Then 
		NewRow = Result.Add();
		NewRow.Id	= String(CardKind.Ref.UUID());
		NewRow.Description	= CardKind.Description;
		NewRow.ThisIsNameCard	= CardKind.Personalized;
	Else
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	LoyaltyCardKinds.Ref AS Ref,
		|	LoyaltyCardKinds.Description AS Description,
		|	LoyaltyCardKinds.Personalized AS ThisIsNameCard
		|FROM
		|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
		|WHERE
		|	NOT LoyaltyCardKinds.DeletionMark
		|	AND LoyaltyCardKinds.ValidityStartDate <= &SessionDate
		|	AND (LoyaltyCardKinds.ValidityEndDate = DATETIME(1,1,1)
		|		OR LoyaltyCardKinds.ValidityEndDate >= &SessionDate)";
		
		Query.SetParameter("SessionDate", CurrentSessionDate());
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			NewRow = Result.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Id = String(Selection.Ref.UUID());
		EndDo;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Fills in the structure of the Loyalty Server response with turnover data
//
// Parameters:
//  DiscountCard - DefinedType.LoyaltyCardOfLoyaltyServer - 
//                    loyalty card that will be used to fill in bonus data
//  ResponseStructure - See LoyaltyServiceOverridable.FillInSalesTurnoverData.ResponseStructure
//
Procedure FillInSalesTurnoverData(DiscountCard, ResponseStructure) Export
	
	ResponseStructure.SellCount = GetTurnoverOfCustomerSales(DiscountCard);
	
EndProcedure

// Fills in the customer loyalty card
//
// Parameters:
//  UniqueIdentifierString - String - unique card ID,
//  CustomerCard - CatalogRef.LoyaltyCards - Customer Card
//
Procedure GetCustomerCardWithUniqueIdentifier(UniqueIdentifierString, CustomerCard) Export

	SetPrivilegedMode(True);
	CustomerCard = Catalogs.LoyaltyCards.GetRef(New UUID(UniqueIdentifierString));
	
EndProcedure

// Control of received customer card data
// Parameters:
//	MethodParameters - See LoyaltyService.ClientCardDataParameters
//	ResponseStructure - See LoyaltyServiceOverridable.CheckClientSCardDetails.ResponseStructure
Procedure CheckClientSCardDetails(MethodParameters, ResponseStructure) Export
	
	SetPrivilegedMode(True);
	UseLoyaltyCards = Constants.UseLoyaltyCards.Get();
	SetPrivilegedMode(False);

	If Not UseLoyaltyCards Then
		ResponseStructure.Error = True;
		ResponseStructure.ErrorMessage = NStr("vi = 'Không hỗ trợ thẻ khách hàng thân thiết.';
												|ru = 'Карты лояльности не поддерживаются.';
												|en = 'Loyalty cards are not supported.'; fa = 'Loyalty cards are not supported.';
												|it = 'Loyalty cards are not supported.';
												|pl = 'Loyalty cards are not supported.';
												|tr = 'Sadakat kartı desteklenmiyor.'", Common.DefaultLanguageCode());
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Returns data on item Balances by warehouse and characteristics. 
// Used in the Loyalty Server HTTP service method.
// For example, a store has run out of goods with a certain characteristic and the cashier can check which stores
// have this product and with what characteristics.
//
// Parameters:
//  MethodParameters - Structure - contains parameters for obtaining Balances.
//  ResponseStructure - Structure - contains data about the certificate balance,
//                                See LoyaltyServiceOverridable.GetBalance.ResponseStructure
//
Procedure BalancesByItemByWarehousesAndCharacteristics(MethodParameters, ResponseStructure) Export
	
	ArrayOfBalances = New Array;
	
	BalanceTable = TableOfBalancesByParameters(MethodParameters);
	
	For Each RemainderLine_ In BalanceTable Do
		StructureOfResidues = LoyaltyService.GetBalanceRequestParameters();
		StructureOfResidues.LeftoverLocation = RemainderLine_.StorageLocation;
		StructureOfResidues.Variant = RemainderLine_.Characteristic;
		StructureOfResidues.Leftover = RemainderLine_.Balance;
		StructureOfResidues.Reserved = RemainderLine_.InReserve;
		StructureOfResidues.FreeLeftover = RemainderLine_.AvailableForInventoryAllocation;
		
		ArrayOfBalances.Add(StructureOfResidues);
	EndDo;
	
	ResponseStructure.Insert("LeftoversList", ArrayOfBalances);
	
EndProcedure

// Returns a table of Balances
//
// Parameters:
//  ParametersForObtainingBalances - Structure - contains parameters for obtaining Balances.
//
// Returns:
//  ValueTable:
//   *StorageLocation - CatalogRef.Warehouses
//   *Characteristic - CatalogRef.ItemsCharacteristics
//   *Balance - Number - 
//   *InReserve - Number -
//   *AvailableForInventoryAllocation - Number -
//
Function TableOfBalancesByParameters(ParametersForObtainingBalances)
	
	QueryText = 
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Products = &Products
		|			AND Purpose = VALUE(Catalog.Assignments.EmptyRef)) AS Inventories
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	ISNULL(REFPRESENTATION(Calculation.Warehouse), """") AS StorageLocation,
		|	ISNULL(REFPRESENTATION(Calculation.Characteristic), """") AS Characteristic,
		|	Calculation.QuantityWithoutControlOfReservesForShipAction
		|		/ ISNULL(&QueryTextPackagingFactor, 1) AS Balance,
		|	Calculation.QuantityForShipAction
		|		/ ISNULL(&QueryTextPackagingFactor, 1) AS AvailableForInventoryAllocation,
		|	(Calculation.QuantityWithoutControlOfReservesForShipAction - Calculation.QuantityForShipAction)
		|		/ ISNULL(&QueryTextPackagingFactor, 1) AS InReserve
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|WHERE
		|	Calculation.QuantityForShipAction > 0";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Query = New Query(QueryText);
	Query.SetParameter("Products", ParametersForObtainingBalances.Products);
	Query.SetParameter("Characteristic", ParametersForObtainingBalances.Characteristic);
	Query.SetParameter("Package", ParametersForObtainingBalances.Package);
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)", // @query-part-1
		"Calculation.Products"); // @query-part-1
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor", QueryTextPackagingFactor);
	
	BalanceTable = Query.Execute().Unload();
	
	Return BalanceTable;
	
EndFunction

// Returns the structure of a parameter from an http request
//
// Parameters:
//  IncomingData - String - contains the string value of the request body in JSON format.
//  Result - Structure - contains a set of parameters that can be passed via an hhtp request:
//    * Products 	- String
//    * Characteristic 	- String
//    * Package 		- String
//
Procedure ParametersFromGetBalancesRequest(IncomingData, Result) Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("HasErrors", False);
	CalculationParameters.Insert("ErrorDescription", "");
	
	Try
	
		JSONReader = New JSONReader();
		JSONReader.SetString(IncomingData);
		IncomingDataInJSON = ReadJSON(JSONReader, , "CurrentDate", JSONDateFormat.ISO);
		JSONReader.Close();
		
		Products = LoyaltyService.GetDeserializedReferenceValue(IncomingDataInJSON, "Item", "Catalogs.Products");
		Characteristic = LoyaltyService.GetDeserializedReferenceValue(IncomingDataInJSON, "Variant", "Catalogs.ItemsCharacteristics");
		Package = LoyaltyService.GetDeserializedReferenceValue(IncomingDataInJSON, "Package", "Catalogs.PackagesAndUnitsOfMeasure");
		
		ParametersForObtainingBalances = New Structure("Products, Characteristic, Package", Products, Characteristic, Package);
		
	Except
		
		LongDesc = StrTemplate(NStr("vi = 'Lỗi chuyển đổi nội dung truy vấn theo ngyên nhân: %1';
									|ru = 'Ошибка преобразования тела запроса по причине: %1';
									|en = 'An error occurred when converting the request body. Reason: %1'; fa = 'An error occurred when converting the request body. Reason: %1';
									|it = 'Ошибка преобразования тела запроса по причине: %1';
									|pl = 'An error occurred when converting the request body. Reason: %1';
									|tr = 'Talep cismi dönüştürme işleminin hata nedeni: %1'"), ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		CalculationParameters.HasErrors = True;
		CalculationParameters.ErrorDescription = LongDesc;
		
		WriteLogEvent("LoyaltyServer.GetBalance",
			EventLogLevel.Error,,,
			LongDesc);
		
	EndTry;
	
	Result = ParametersForObtainingBalances;
	
EndProcedure

Function CheckCorrectnessOfIncomingData(IncomingData, CalculationParameters)
	
	ArrayOfParametersToCheck = ArrayOfRequiredDiscountCalculationParameters();
	
	For Each ParameterBeingChecked In ArrayOfParametersToCheck Do
		If Not CommonClientServer.HasAttributeOrObjectProperty(IncomingData, ParameterBeingChecked) Then
			ErrorDescription = StrTemplate(NStr("vi = 'Trong các tham số đầu vào chưa tìm thấy tham số %1';
												|ru = 'Во входящих параметрах не обнаружен параметр %1';
												|en = 'The %1 parameter is not found in the incoming parameters'; fa = 'The %1 parameter is not found in the incoming parameters';
												|it = 'Во входящих параметрах не обнаружен параметр %1';
												|pl = 'The %1 parameter is not found in the incoming parameters';
												|tr = 'Gelen parametrelerde %1 parametresi bulunamadı'"), ParameterBeingChecked);
			CalculationParameters.ErrorDescription = CalculationParameters.ErrorDescription + ErrorDescription + ?(IsBlankString(CalculationParameters.ErrorDescription), "", Chars.LF);
			CalculationParameters.HasErrors = True;
		EndIf;
	EndDo;
	
	Return Not CalculationParameters.HasErrors;
	
EndFunction

Function ArrayOfRequiredDiscountCalculationParameters()
	
	ParametersArray = New Array;
	ParametersArray.Add("ObjectTime");
	ParametersArray.Add("LoyaltyCardsList");
	ParametersArray.Add("Goods");
	ParametersArray.Add("RetailStore");
	
	Return ParametersArray;
	
EndFunction

Function GetLoyaltyCardDetails(LoyaltyCard)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	ISNULL(Partners.Ref, """") AS Cardholder,
	|	ISNULL(Partners.DescriptionFull, """") AS PartnerPresentation,
	|	CASE
	|		WHEN LoyaltyCards.Owner.CardType = VALUE(Enum.CardTypes.Barcode_)
	|			THEN LoyaltyCards.Barcode
	|		ELSE LoyaltyCards.MagneticCode
	|	END AS CardNumber,
	|	ISNULL(ContactInformationPhone.Presentation, """") AS PhoneNumber,
	|	ISNULL(ContactInformationEmail.Presentation, """") AS Email,
	|	ISNULL(Partners.BirthDate, DATETIME(1, 1, 1)) AS BirthDate,
	|	ISNULL(LoyaltyCardKinds.LoyaltyProgram.MaximumSharePayableByPoints, 0) AS MaximumSharePayableByPoints
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationPhone
	|		ON LoyaltyCards.Partner = ContactInformationPhone.Ref
	|			AND (ContactInformationPhone.KindForList = VALUE(Catalog.ContactInformationKinds.PartnerSPhoneNumber))
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationEmail
	|		ON LoyaltyCards.Partner = ContactInformationEmail.Ref
	|			AND (ContactInformationEmail.KindForList = VALUE(Catalog.ContactInformationKinds.EmailPartner_))
	|		INNER JOIN Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|		ON LoyaltyCards.Owner = LoyaltyCardKinds.Ref
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON LoyaltyCards.Partner = Partners.Ref
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard
	|	AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
	|";
	
	Query.SetParameter("LoyaltyCard", LoyaltyCard);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function GetClientData(Client)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Partners.Ref AS Cardholder,
	|	Partners.DescriptionFull AS PartnerPresentation,
	|	ISNULL(ContactInformationPhone.Presentation, """") AS PhoneNumber,
	|	ISNULL(ContactInformationEmail.Presentation, """") AS Email,
	|	ISNULL(Partners.BirthDate, DATETIME(1, 1, 1)) AS BirthDate
	|FROM
	|	Catalog.Partners AS Partners
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationPhone
	|		ON Partners.Ref = ContactInformationPhone.Ref
	|			AND (ContactInformationPhone.KindForList = VALUE(Catalog.ContactInformationKinds.PartnerSPhoneNumber))
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationEmail
	|		ON Partners.Ref = ContactInformationEmail.Ref
	|			AND (ContactInformationEmail.KindForList = VALUE(Catalog.ContactInformationKinds.EmailPartner_))
	|WHERE
	|	Partners.Ref = &Client";
	
	Query.SetParameter("Client", Client);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function CheckCardDetails(CardCode, CardKind)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	TemplatesOfLoyaltyCardCodes.Ref                                              AS Ref,
	|	TemplatesOfLoyaltyCardCodes.Ref.Status                                       AS Status,
	|	TemplatesOfLoyaltyCardCodes.Ref.Personalized                            AS Personalized,
	|	TemplatesOfLoyaltyCardCodes.Ref.CardType                                     AS CardType,
	|	TemplatesOfLoyaltyCardCodes.Ref.AllowAutoRegistrationAtFirstReading AS AllowAutoRegistrationAtFirstReading,
	|	TemplatesOfLoyaltyCardCodes.Ref.ValidityStartDate                           AS ValidityStartDate,
	|	TemplatesOfLoyaltyCardCodes.Ref.ValidityEndDate                        AS ValidityEndDate,
	|	TemplatesOfLoyaltyCardCodes.Ref.Organization                                  AS Organization
	|FROM
	|	Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
	|WHERE
	|	TemplatesOfLoyaltyCardCodes.Ref = &CardKind
	|	AND TemplatesOfLoyaltyCardCodes.StartOfBarcodeRange <= &CardCode
	|	AND TemplatesOfLoyaltyCardCodes.EndOfBarcodeRange >= &CardCode
	|	AND TemplatesOfLoyaltyCardCodes.BarcodeLength = &CodeLength
	|	AND TemplatesOfLoyaltyCardCodes.Ref.Status = VALUE(Enum.StatusesOfLoyaltyCardKinds.Valid)
	|";
	Query.SetParameter("CardKind", CardKind);
	Query.SetParameter("CardCode", CardCode);
	Query.SetParameter("CodeLength", StrLen(CardCode));
	Selection = Query.Execute().Select();
	Return Selection.Next();
	
EndFunction

// Gets a valid type of discount card by ID
//
// Parameters:
//  MapViewGUIDE - UUID
//  
// Returns:
//  CatalogRef.LoyaltyCardKinds
//
Function GetTypeOfLoyaltyCard(MapViewGUIDE = Undefined) Export
	
	CardKind = Undefined;
	
	If MapViewGUIDE = Undefined Then
		
		CardKind = Constants.CardKindLoyaltyServer.Get();
		
		If Not ValueIsFilled(CardKind) Then 
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED TOP 1
			|	LoyaltyCardKinds.Ref AS Ref
			|FROM
			|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
			|WHERE
			|	NOT LoyaltyCardKinds.DeletionMark
			|	AND LoyaltyCardKinds.Personalized";
			
			QueryResult = Query.Execute();
			
			Selection = QueryResult.Select();
			
			If Selection.Next() Then
				CardKind = Selection.Ref;
			EndIf;
		EndIf;
		
	Else
		
		If ValueIsFilled(MapViewGUIDE)
				And Not MapViewGUIDE = CommonClientServer.BlankUUID() Then
			CardKind = Catalogs.LoyaltyCardKinds.GetRef(New UUID(MapViewGUIDE));
		EndIf;
		
	EndIf;
	
	Return CardKind;
	
EndFunction

Function GetDeserializedItemTable(IncomingData, ParameterName)
	
	TypesDetailsNumber = New TypeDescription("Number", , , New NumberQualifiers(15,2));
	DescriptionOfTypesNumberForQuantity = New TypeDescription("Number", , , New NumberQualifiers(15,3));
	
	TableOfGoods = New ValueTable;
	TableOfGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableOfGoods.Columns.Add("OrderDocument", New TypeDescription("DocumentRef.SalesOrder"));
	TableOfGoods.Columns.Add("TypeOfMinimumPrices", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	TableOfGoods.Columns.Add("NumberOfPackages", DescriptionOfTypesNumberForQuantity);
	TableOfGoods.Columns.Add("Count", DescriptionOfTypesNumberForQuantity);
	TableOfGoods.Columns.Add("Sum", TypesDetailsNumber);
	TableOfGoods.Columns.Add("Price", TypesDetailsNumber);
	TableOfGoods.Columns.Add("ConnectionKey", TypesDetailsNumber);
	TableOfGoods.Columns.Add("LineNumber", TypesDetailsNumber);
	TableOfGoods.Columns.Add("PercentRateOfManualDiscount", TypesDetailsNumber);
	TableOfGoods.Columns.Add("ManualDiscount", TypesDetailsNumber);
	TableOfGoods.Columns.Add("AmountOfDiscountOfBonusPayment", TypesDetailsNumber);
	TableOfGoods.Columns.Add("PercentRateOfAutomaticDiscountMarkup", TypesDetailsNumber);
	TableOfGoods.Columns.Add("DiscountMarkupAmount", TypesDetailsNumber);
	TableOfGoods.Columns.Add("Total", TypesDetailsNumber);
	TableOfGoods.Columns.Add("VATAmount", TypesDetailsNumber);
	TableOfGoods.Columns.Add("RowID", New TypeDescription("String"));
	
	ArrayOfTableRows = IncomingData[ParameterName];
	
	VATRateTable = New ValueTable;
	VATRateTable.Columns.Add("RateLine", New TypeDescription("String",,,,New StringQualifiers(10)));
	
	For Each TableRow In ArrayOfTableRows Do
		NewRow = VATRateTable.Add();
		NewRow.RateLine = TableRow.VATRate;
	EndDo;
	
	VATRateByName(VATRateTable);
	
	LineNumber = 1;
	
	For Each TableRow In ArrayOfTableRows Do
		
		NewRow = TableOfGoods.Add();
		NewRow.Products = LoyaltyService.GetDeserializedReferenceValue(TableRow, "Item", "Catalogs.Products");
		NewRow.Package = LoyaltyService.GetDeserializedReferenceValue(TableRow, "Package", "Catalogs.PackagesAndUnitsOfMeasure");
		NewRow.Characteristic = LoyaltyService.GetDeserializedReferenceValue(TableRow, "Variant", "Catalogs.ItemsCharacteristics");
		NewRow.Price = TableRow.Price;
		NewRow.Sum = TableRow.Amount;
		NewRow.Count = TableRow.Count;
		NewRow.NumberOfPackages = TableRow.PackagesCount;
		NewRow.PercentRateOfAutomaticDiscountMarkup = TableRow.PercentOfAutomaticDiscount;
		NewRow.PercentRateOfManualDiscount = TableRow.PercentOfManualDiscount;
		NewRow.DiscountMarkupAmount = TableRow.AmountOfAutomaticDiscount;
		NewRow.ManualDiscount = TableRow.AmountOfManualDiscount;
		NewRow.Total = TableRow.TotalAmount;
		NewRow.VATAmount = TableRow.VATAmount;
		NewRow.RowID = TableRow.LineUID;
		
		NewRow.ConnectionKey = LineNumber;
		NewRow.LineNumber = LineNumber;
		
		LineRate = VATRateTable.Find(TableRow.VATRate, "RateLine");
		If LineRate <> Undefined Then
			NewRow.VATRate = LineRate.Ref;
		EndIf;
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	Return TableOfGoods;
	
EndFunction

Function GetDeserializedTableOfSelectedManagedDiscounts(IncomingData, ParameterName)
	
	TableOfSelectedManagedDiscounts = New ValueTable;
	TableOfSelectedManagedDiscounts.Columns.Add("DiscountID", New TypeDescription("String"));
	TableOfSelectedManagedDiscounts.Columns.Add("DiscountMarkup", New TypeDescription("CatalogRef.DiscountsMarkups"));
	TableOfSelectedManagedDiscounts.Columns.Add("RowID", New TypeDescription("String"));
	TableOfSelectedManagedDiscounts.Columns.Add("ConnectionKey", New TypeDescription("Number", , , New NumberQualifiers(10,0)));
	
	ArrayOfTableRows = IncomingData[ParameterName];
	
	For Each TableRow In ArrayOfTableRows Do
		
		NewRow = TableOfSelectedManagedDiscounts.Add();
		NewRow.DiscountID = TableRow.ControlledDiscountUID;
		NewRow.DiscountMarkup = Catalogs.DiscountsMarkups.GetRef(New UUID(TableRow.ControlledDiscountUID));
		NewRow.RowID = TableRow.LineUID;
		NewRow.ConnectionKey = TableRow.KeyRelation;
		
	EndDo;
	
	Return TableOfSelectedManagedDiscounts;
	
EndFunction

Procedure VATRateByName(VATRateTable)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	TT.RateLine AS RateLine
		|INTO TableOfNDSVTRate
		|FROM
		|	&VATRateTable AS TT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfNDSVTRate.RateLine AS RateLine,
		|	VATRates.Ref AS Ref
		|FROM
		|	TableOfNDSVTRate AS TableOfNDSVTRate
		|		LEFT JOIN Catalog.VATRates AS VATRates
		|		ON (CASE
		|				WHEN SUBSTRING(STRREPLACE(STRREPLACE(LOWER(TableOfNDSVTRate.RateLine), "" "", """"), ""%"", """"), 1, 3) = SUBSTRING(STRREPLACE(VATRates.Description, ""%"", """"), 1, 3)
		|					THEN TRUE
		|			END)
		|
		|GROUP BY
		|	VATRates.Ref,
		|	TableOfNDSVTRate.RateLine";
	
	Query.SetParameter("VATRateTable", VATRateTable);
	VATRateTable = Query.Execute().Unload();
	
EndProcedure

// Serializes calculation parameters into a structure
//
// Parameters:
//  Object - CatalogRef
//  
// Returns:
//  Array of Structure:
//    *  Item						- See GetLinkStructure
//    *  Variant					- See GetLinkStructure
//    *  Package					- See GetLinkStructure
//    *  Count						- Number
//    *  PackagesCount				- Number
//    *  Price						- Number
//    *  Amount						- Number
//    *  TotalAmount				- Number
//    *  LineUID					- String
//    *  VATRate					- String
//    *  VATAmount					- Number
//    *  AmountOfAutomaticDiscount	- Number
//    *  AmountOfManualDiscount		- Number
//    *  PercentOfAutomaticDiscount	- Number
//    *  PercentOfManualDiscount	- Number
//
Function SerializeCalculationResult(Object)
	
	SerializedDiscountStructure = New Structure;
	
	ArrayOfProducts_2 = New Array;
	
	For Each RowGoods In Object.Goods Do
	
		StringStructure = New Structure;
		
		StringStructure.Insert("Item", GetLinkStructure(RowGoods.Products));
		StringStructure.Insert("Variant", GetLinkStructure(RowGoods.Characteristic));
		StringStructure.Insert("Package", GetLinkStructure(RowGoods.Package));
		StringStructure.Insert("Count", RowGoods.Count);
		StringStructure.Insert("PackagesCount", RowGoods.NumberOfPackages);
		StringStructure.Insert("Price", RowGoods.Price);
		StringStructure.Insert("Amount", RowGoods.Sum);
		StringStructure.Insert("TotalAmount", RowGoods.Sum);
		StringStructure.Insert("LineUID", RowGoods.RowID);
		StringStructure.Insert("VATRate", String(RowGoods.VATRate));
		StringStructure.Insert("VATAmount", RowGoods.VATAmount);
		ThisIsReturn = TypeOf(Object) = Type("DocumentObject.CashRegisterReceiptReturn");
		If ThisIsReturn Then
			StringStructure.Insert("AmountOfAutomaticDiscount", 0);
			StringStructure.Insert("AmountOfManualDiscount",  0);
			StringStructure.Insert("PercentOfAutomaticDiscount",  0);
			StringStructure.Insert("PercentOfManualDiscount", 0);
		Else
			StringStructure.Insert("AmountOfAutomaticDiscount", RowGoods.DiscountMarkupAmount);
			StringStructure.Insert("AmountOfManualDiscount",  RowGoods.ManualDiscount);
			StringStructure.Insert("PercentOfAutomaticDiscount",  RowGoods.PercentRateOfAutomaticDiscountMarkup);
			StringStructure.Insert("PercentOfManualDiscount", RowGoods.PercentRateOfManualDiscount);
		EndIf;
		
		ArrayOfProducts_2.Add(StringStructure);
		
	EndDo;
		
	SerializedDiscountStructure.Insert("Goods", ArrayOfProducts_2);
	
	Return SerializedDiscountStructure;
	
EndFunction

// Returns the structure of the link for its subsequent conversion to JSON
//
// Parameters:
//  Ref - AnyRef
//
// Returns:
//  Structure:
//    *Ref  - String - the string value of the GUID of the transmitted link.
//    *Name - String - name of the transmitted link.
//
Function GetLinkStructure(Ref)
	
	RefStructure = New Structure;
	RefStructure.Insert("Ref", XMLString(Ref));
	RefStructure.Insert("Name", Common.ObjectAttributeValue(Ref, "Description"));
	
	Return RefStructure;
	
EndFunction

// Gets a discount card
//
// Parameters:
//  IncomingData - Structure - a structure containing http request parameters.
//  ParameterName - String - the name of the parameter that contains the discount card you are looking for.
//  Result - Undefined, DefinedType.LoyaltyCardOfLoyaltyServer - the discount card found.
//
Procedure GetDiscountCard(IncomingData, ParameterName, Result)
	
	DiscountCard = Catalogs.LoyaltyCards.EmptyRef();
	
	If TypeOf(IncomingData) = Type("Structure") Then
		
		ArrayOfCardNumbers = IncomingData[ParameterName];
		
		If ValueIsFilled(ArrayOfCardNumbers) Then
			
			MapSearchParameters = New Structure;
			MapSearchParameters.Insert("IdOfClientSCard", ArrayOfCardNumbers[0]);
			MapSearchParameters.Insert("Client", "");
			MapSearchParameters.Insert("PhoneNumber", "");
			MapSearchParameters.Insert("EMAddress", "");
			MapSearchParameters.Insert("MapViewGUIDE", "");
			
			FoundMap = Undefined;
			FindCustomerCard(MapSearchParameters, FoundMap);
			If FoundMap <> Undefined Then
				DiscountCard = FoundMap;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Result = DiscountCard;
	
EndProcedure

// Looking for a client by name
// 
// Parameters:
//  CardData - Structure - structure containing loyalty card data:
//    * IdOfClientSCard	 - String - loyalty card code
//    * Client						 - String - Full name of the cardholder
//    * EMAddress						 - String - e-mail address of the cardholder
//    * PhoneNumber				 - String - phone number of the cardholder
//
// Returns:
//  Structure - search result/ creation of a cardholder:
//    * Cardholder - CatalogRef.Partners, Undefined - loyalty card holder
//    * StatusOfReceipt - Number - possible values: 1-created, 2-found, 3-busy (found a similar, but different client)
//
Function GetCardholder(CardData) Export
	
	FunctionResult = New Structure("Cardholder,StatusOfReceipt", Undefined, 0);
	
	PhoneNumber = CardData.PhoneNumber;
	Query = New Query;
	If ValueIsFilled(PhoneNumber) Then
		PhoneSearchBar = PrepareSearchStringByPhoneNumber(PhoneNumber);
		Query.Text = QueryTextOfClientByPhoneNumber(PhoneSearchBar);
		Query.SetParameter("PhoneNumber", PhoneSearchBar);
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			FunctionResult.Insert("Cardholder", Selection.Client);
			FunctionResult.Insert("StatusOfReceipt", 2);
		EndIf;
	ElsIf ValueIsFilled(CardData.EMAddress) Then
		Query.Text = QueryTextOfClientWithPhoneNumberAtItemInstanceAddress();
		Query.SetParameter("EMAddress", CardData.EMAddress);
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			FunctionResult.Insert("Cardholder", Selection.Client);
			If Selection.PhoneNumber = "" Then
				FunctionResult.Insert("StatusOfReceipt", 2);
			Else
				FunctionResult.Insert("StatusOfReceipt", 3);
			EndIf;
		EndIf;
	EndIf;
	
	If FunctionResult.Cardholder = Undefined Then
		
		MapDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
		
		MapDataStructure.AccessGroup			= Constants.PartnerSAccessGroupAtAutoCreation.Get();
		MapDataStructure.Barcode				= CardData.IdOfClientSCard;
		MapDataStructure.Fiopartner			= CardData.Client;
		MapDataStructure.PartnerSDateOfBirth	= CardData.BirthDate;
		MapDataStructure.PhoneNumber			= CardData.PhoneNumber;
		MapDataStructure.Email		= CardData.EMAddress;
		MapDataStructure.CreateCounterparty	= True;
		
		Cardholder = LoyaltyCardsServer.CreateLoyaltyCardHolderPartner(MapDataStructure);
		FunctionResult.Insert("Cardholder", Cardholder);
		FunctionResult.Insert("StatusOfReceipt", 1);
		
	EndIf;
	
	Return FunctionResult;
	
EndFunction

Function GetCardWithUniqueId(UniqueIdentifierString)
	
	SetPrivilegedMode(True);
	
	FunctionResult = Undefined;
	If ValueIsFilled(UniqueIdentifierString)
			And Not UniqueIdentifierString = CommonClientServer.BlankUUID() Then
			
		FunctionResult
			= Catalogs.LoyaltyCards.GetRef(New UUID(UniqueIdentifierString));
			
	EndIf;
	
	Return FunctionResult;
	
EndFunction

Function GetCardholderByUniqueId(UniqueIdentifierString)
	
	SetPrivilegedMode(True);
	
	FunctionResult = Undefined;
	If ValueIsFilled(UniqueIdentifierString)
			And Not UniqueIdentifierString = CommonClientServer.BlankUUID() Then
			
		FunctionResult
			= Catalogs.Partners.GetRef(New UUID(UniqueIdentifierString));
			
	EndIf;
	
	Return FunctionResult;
	
EndFunction

// Parameters:
// CustomerCard - See GetCardWithUniqueId
// ResponseStructure - See FindLoyaltyCards.ResponseStructure
Procedure FindLoyaltyCardByFollowingLink(CustomerCard, ResponseStructure)
	
	RequestingMaps = New Query;
	RequestingMaps.Text = QueryTextOfLoyaltyCardByLink();
	RequestingMaps.SetParameter("LoyaltyCard", CustomerCard);
	RequestingMaps.SetParameter("QueryPeriod", EndOfDay(CurrentSessionDate()));
	FillInMapDescriptionsBasedOnRequestResult(RequestingMaps, ResponseStructure);
	
EndProcedure

Procedure FindLoyaltyCardByOwner(Cardholder, ResponseStructure)
	
	RequestingMaps = New Query;
	RequestingMaps.Text = QueryTextOfLoyaltyCardsByCardholder();
	RequestingMaps.SetParameter("Cardholder", Cardholder);
	RequestingMaps.SetParameter("QueryPeriod", EndOfDay(CurrentSessionDate()));
	FillInMapDescriptionsBasedOnRequestResult(RequestingMaps, ResponseStructure);
	
EndProcedure

Procedure FindLoyaltyCardByCardNumber(IdOfClientSCard, ResponseStructure)

	RequestingMaps = New Query;
	RequestingMaps.Text = QueryTextOfLoyaltyCardsByNumber();
	RequestingMaps.SetParameter("IdOfClientSCard", IdOfClientSCard);
	RequestingMaps.SetParameter("QueryPeriod", EndOfDay(CurrentSessionDate()));
	FillInMapDescriptionsBasedOnRequestResult(RequestingMaps, ResponseStructure);
	
EndProcedure

Procedure FindLoyaltyCardsByContactInformation(PhoneSearchBar, EMAddress, ResponseStructure)
	
	RequestingMaps = New Query;
	RequestingMaps.Text = LoyaltyCardQueryTextForContactDetails(PhoneSearchBar);
	RequestingMaps.SetParameter("PhoneNumber", PhoneSearchBar);
	RequestingMaps.SetParameter("EMAddress", EMAddress);
	RequestingMaps.SetParameter("QueryPeriod", EndOfDay(CurrentSessionDate()));
	FillInMapDescriptionsBasedOnRequestResult(RequestingMaps, ResponseStructure);
	
EndProcedure

// Parameters:
//	RequestingMaps - Query
//	ResponseStructure - See FindLoyaltyCardByFollowingLink.ResponseStructure 
Procedure FillInMapDescriptionsBasedOnRequestResult(RequestingMaps, ResponseStructure)
	
	QueryResult = RequestingMaps.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		MapSelection = QueryResult.Select();
		
		While MapSelection.Next() Do
			MapDescription = LoyaltyService.LoyaltyCardStructure();
			FillInCardDescription(MapDescription, MapSelection);
			ResponseStructure.LoyaltyCardsList.Add(MapDescription);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInCardDescription(MapDescription, Data)
	
	MapDescription.ClientName				= Data.PartnerName_;
	MapDescription.IsPerson					= (Data.LegalEntityIndividual = Enums.LegalEntityIndividual.Person);
	MapDescription.DateOfBirth				= Data.BirthDate;
	MapDescription.Phone						= Data.PhoneNumber;
	MapDescription.Email						= Data.EMAddress;
	MapDescription.Barcode					= Data.Barcode;
	MapDescription.MagneticCode				= Data.MagneticCode;
	MapDescription.CardGUID					= String(Data.Map.UUID());
	MapDescription.ClientGUID				= String(Data.Partner.UUID());
	MapDescription.IsBlocked					= Data.BonusesAreBlocked;
	MapDescription.BonusData.PaymentPercent	= Data.MaximumSharePayableByPoints;
	MapDescription.BonusData.BonusCount		= ?(MapDescription.IsBlocked, 0, Data.BonusBalance);
	MapDescription.BonusData.BonusCurrency	= Data.CurrencyCodeOfBonusConversion;
	MapDescription.BonusData.BonusRate		= Data.ConversionRateOfBonusesIntoCurrency;
	MapDescription.SellCount					= Data.SalesTurnover;
	MapDescription.SearchType				= TypeOfSearchByCode(Data.FindType);
	
EndProcedure

Function QueryTextOfClientByPhoneNumber(PhoneSearchBar)
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	PartnersContactInformation.Ref AS Client
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.PhoneNumber = &PhoneNumber
	|	AND PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|	AND NOT PartnersContactInformation.Ref.DeletionMark";
	
	If ValueIsFilled(PhoneSearchBar) And Left(PhoneSearchBar, 1) = "%" Then
		QueryText = StrReplace(QueryText, "PhoneNumber = &PhoneNumber",
			"PhoneNumber LIKE &PhoneNumber");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextOfClientWithPhoneNumberAtItemInstanceAddress()
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	PartnersContactDetailsItemInstanceAddress.Ref AS Client,
	|	ISNULL(PartnersContactDetailsPhone.PhoneNumber, """") AS PhoneNumber
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactDetailsItemInstanceAddress
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PartnersContactDetailsPhone
	|		ON PartnersContactDetailsItemInstanceAddress.Ref = PartnersContactDetailsPhone.Ref
	|			AND (PartnersContactDetailsPhone.Type = VALUE(Enum.ContactInformationTypes.Phone))
	|			AND (NOT PartnersContactDetailsPhone.PhoneNumber = """")
	|WHERE
	|	PartnersContactDetailsItemInstanceAddress.EMAddress = &EMAddress
	|	AND NOT PartnersContactDetailsItemInstanceAddress.Ref.DeletionMark
	|	AND PartnersContactDetailsItemInstanceAddress.Type = VALUE(Enum.ContactInformationTypes.Email)";
	
	Return QueryText;
	
EndFunction

Function QueryTextOfLoyaltyCardsByCardholder()
	
	QueryText =
	"SELECT ALLOWED
	|	LoyaltyCards.Ref AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	1 AS FindType
	|INTO LoyaltyCards
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Partner = &Cardholder 
	|	AND NOT LoyaltyCards.DeletionMark
	|	AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + GeneralPartOfLoyaltyCardRequest();
	
	Return QueryText;
	
EndFunction

Function QueryTextOfLoyaltyCardByLink()
	
	QueryText =
	"SELECT ALLOWED
	|	LoyaltyCards.Ref AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	0 AS FindType
	|INTO LoyaltyCards
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard"
	+ "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + GeneralPartOfLoyaltyCardRequest();
	
	Return QueryText;
	
EndFunction

Function QueryTextOfLoyaltyCardsByNumber()
	
	QueryText =
	"SELECT ALLOWED TOP 1
	|	LoyaltyCards.Ref AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	2 AS FindType
	|INTO LoyaltyCards
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	NOT LoyaltyCards.DeletionMark
	|	AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
	|	AND &IdOfClientSCard IN (LoyaltyCards.Barcode, LoyaltyCards.MagneticCode)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + GeneralPartOfLoyaltyCardRequest();
	
	Return QueryText;
	
EndFunction

Function LoyaltyCardQueryTextForContactDetails(PhoneSearchBar)
	
	QueryText =
	"SELECT ALLOWED
	|	PartnersContactInformation.Ref AS Partner,
	|	3 AS FindType
	|INTO Partners
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	&PhoneNumber <> """"
	|	AND PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|	AND NOT PartnersContactInformation.Ref.DeletionMark
	|	AND PartnersContactInformation.PhoneNumber = &PhoneNumber
	|
	|UNION ALL
	|
	|SELECT
	|	PartnersContactInformation.Ref,
	|	4 AS FindType
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	&EMAddress <> """"
	|	AND PartnersContactInformation.EMAddress = &EMAddress
	|	AND NOT PartnersContactInformation.Ref.DeletionMark
	|	AND PartnersContactInformation.Type = VALUE(Enum.ContactInformationTypes.Email)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	LoyaltyCards.Ref AS Map,
	|	Partners.Partner AS Partner,
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	Partners.FindType AS FindType
	|INTO LoyaltyCards
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|		INNER JOIN Partners AS Partners
	|		ON LoyaltyCards.Partner = Partners.Partner
	|WHERE
	|	NOT LoyaltyCards.DeletionMark
	|	AND LoyaltyCards.Status = VALUE(Enum.LoyaltyCardStatuses.Valid)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" + GeneralPartOfLoyaltyCardRequest();
	
	If ValueIsFilled(PhoneSearchBar) And Left(PhoneSearchBar, 1) = "%" Then
		QueryText = StrReplace(QueryText, "PhoneNumber = &PhoneNumber",
			"PhoneNumber LIKE &PhoneNumber");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function GeneralPartOfLoyaltyCardRequest()
	
	QueryText =
	"SELECT
	|	LoyaltyCards.Map AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	SUM(ISNULL(BonusPointsToWriteOff.ToWriteOff, 0)) AS ToWriteOff
	|INTO ReserveLoyaltyCards
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN InformationRegister.BonusPointsToWriteOffAndAccrue AS BonusPointsToWriteOff
	|		ON LoyaltyCards.Map = BonusPointsToWriteOff.DiscountCard
	|
	|GROUP BY
	|	LoyaltyCards.Map,
	|	LoyaltyCards.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LoyaltyCards.Map AS Map,
	|	CASE
	|		WHEN ISNULL(BonusPointsBalance.AccruedBalance, 0) - ISNULL(BonusPointsBalance.ToWriteOffBalance, 0) < 0
	|			THEN 0
	|		ELSE ISNULL(BonusPointsBalance.AccruedBalance, 0) - ISNULL(BonusPointsBalance.ToWriteOffBalance, 0)
	|	END AS Balance
	|INTO LoyaltyCardsBalance
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN AccumulationRegister.BonusPoints.Balance(
	|				&QueryPeriod,
	|				Partner IN
	|					(SELECT
	|						LoyaltyCards.Partner AS Partner
	|					FROM
	|						LoyaltyCards AS LoyaltyCards)) AS BonusPointsBalance
	|		ON LoyaltyCards.Partner = BonusPointsBalance.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LoyaltyCards.Map AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	ContactInformationPhone.PhoneNumber AS PhoneNumber,
	|	ContactDetailsEmail.EMAddress AS EMAddress
	|INTO PartnersContactInformation
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationPhone
	|			ON LoyaltyCards.Partner = ContactInformationPhone.Ref
	|			AND ContactInformationPhone.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactDetailsEmail
	|			ON LoyaltyCards.Partner = ContactDetailsEmail.Ref
	|			AND ContactDetailsEmail.Type = VALUE(Enum.ContactInformationTypes.Email)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LoyaltyCards.Map AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	DimensionKeysOfAccountingByPartners.Ref AS PartnerAnalyticsKey
	|INTO PartnersKeysAnalyst
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|		ON LoyaltyCards.Partner = DimensionKeysOfAccountingByPartners.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LoyaltyCards.Map AS Map,
	|	LoyaltyCards.Partner AS Partner,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS RevenueAmountTurnover
	|INTO LoyaltyCardsSalesTurnover
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN AccumulationRegister.RevenueAndCOGS.Turnovers( , , ,
	|				AccountingDimensionByPartners IN
	|					(SELECT
	|						PartnersKeysAnalyst.Partner AS Partner
	|					FROM
	|						PartnersKeysAnalyst AS PartnersKeysAnalyst)) AS RevenueAndCostOfSalesTurnover
	|		ON LoyaltyCards.Partner = RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LoyaltyCards.Map AS Map,
	|	LoyaltyCards.FindType AS FindType,
	|	LoyaltyCards.Partner AS Partner,
	|	ISNULL(LoyaltyCards.Partner.Presentation, """") AS PartnerName_,
	|	ISNULL(LoyaltyCards.Partner.LegalEntityIndividual, VALUE(Enum.IndividualCompany.EmptyRef)) AS LegalEntityIndividual,
	|	ISNULL(LoyaltyCards.Partner.BirthDate, DATETIME(1, 1, 1)) AS BirthDate,
	|	ISNULL(PartnersContactInformation.PhoneNumber, """") AS PhoneNumber,
	|	ISNULL(PartnersContactInformation.EMAddress, """") AS EMAddress,
	|	LoyaltyCards.Map.Barcode AS Barcode,
	|	LoyaltyCards.Map.MagneticCode AS MagneticCode,
	|	NOT BonusPointState.DiscountCard IS NULL AS BonusesAreBlocked,
	|	ISNULL(LoyaltyCards.Map.Owner.LoyaltyProgram.MaximumSharePayableByPoints, 0) AS MaximumSharePayableByPoints,
	|	CASE
	|		WHEN ISNULL(LoyaltyCardsBalance.Balance, 0) < ISNULL(ReserveLoyaltyCards.ToWriteOff, 0)
	|			THEN 0
	|		ELSE ISNULL(LoyaltyCardsBalance.Balance, 0) - ISNULL(ReserveLoyaltyCards.ToWriteOff, 0)
	|	END AS BonusBalance,
	|	ISNULL(LoyaltyCardsSalesTurnover.RevenueAmountTurnover, 0) AS SalesTurnover,
	|	ISNULL(LoyaltyPrograms.ConversionRateOfBonusesIntoCurrency,0) AS ConversionRateOfBonusesIntoCurrency,
	|	ISNULL(LoyaltyPrograms.BonusConversionCurrency.Code,0) AS CurrencyCodeOfBonusConversion
	|FROM
	|	LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN InformationRegister.BonusPointState AS BonusPointState
	|		ON LoyaltyCards.Map = BonusPointState.DiscountCard
	|		LEFT JOIN LoyaltyCardsBalance AS LoyaltyCardsBalance
	|		ON LoyaltyCards.Map = LoyaltyCardsBalance.Map
	|		LEFT JOIN ReserveLoyaltyCards AS ReserveLoyaltyCards
	|		ON LoyaltyCards.Map = ReserveLoyaltyCards.Map
	|		LEFT JOIN PartnersContactInformation AS PartnersContactInformation
	|		ON LoyaltyCards.Map = PartnersContactInformation.Map
	|		LEFT JOIN LoyaltyCardsSalesTurnover AS LoyaltyCardsSalesTurnover
	|		ON LoyaltyCards.Map = LoyaltyCardsSalesTurnover.Map
	|		LEFT JOIN Catalog.LoyaltyPrograms AS LoyaltyPrograms
	|		ON LoyaltyCards.LoyaltyProgram = LoyaltyPrograms.Ref
	|";
	
	Return QueryText;
	
EndFunction

Function PrepareSearchStringByPhoneNumber(PhoneNumber)
	
	FunctionResult = "";
	NumberLengthWithoutCountryCode = 10;
	MinimumLengthOfPhonePart = 4;
	CountryCodes = NStr("vi = '78';
						|ru = '78';
						|en = '78'; fa = '78';
						|it = '78';
						|pl = '78';
						|tr = '78'");
	PhoneSearchBar = RemoveSeparatorsFromPhoneNumber(PhoneNumber);
	NumberLength = StrLen(PhoneSearchBar);
	If StrFind(PhoneSearchBar, "*") = 1 Then
		If NumberLength = NumberLengthWithoutCountryCode Then
			FunctionResult = PhoneSearchBar;
		ElsIf NumberLength >= MinimumLengthOfPhonePart
				And NumberLength < NumberLengthWithoutCountryCode Then
			FunctionResult = StrTemplate("%1%2", "%", PhoneSearchBar);
		EndIf;
	ElsIf NumberLength = NumberLengthWithoutCountryCode Then
		FunctionResult = PhoneSearchBar;
	ElsIf NumberLength = NumberLengthWithoutCountryCode + 1
			And StrFind(CountryCodes, Left(PhoneSearchBar, 1)) > 0 Then
		FunctionResult = StrTemplate("%1%2", "%", Right(PhoneSearchBar, NumberLengthWithoutCountryCode));
	EndIf;
	
	Return FunctionResult;
	
EndFunction

// Removes separators in the phone number.
//
// Parameters:
//    PhoneNumber - String - phone or Fax number.
//
// Returns:
//     String - phone or fax number without separators.
//
Function RemoveSeparatorsFromPhoneNumber(Val PhoneNumber)
	
	Pos = StrFind(PhoneNumber, ",");
	If Pos <> 0 Then
		PhoneNumber = Left(PhoneNumber, Pos-1);
	EndIf;
	
	PhoneNumber = StrReplace(PhoneNumber, "-", "");
	PhoneNumber = StrReplace(PhoneNumber, " ", "");
	PhoneNumber = StrReplace(PhoneNumber, "+", "");
	
	Return PhoneNumber;
	
EndFunction

// Returns the Balance of the client's bonus points
//
// Parameters: 
//  LoyaltyProgram - CatalogRef.LoyaltyPrograms
//  Partner - CatalogRef.Partners
//
// Returns:
//  Number - Balance of client bonuses
//
Function GetCustomerBonusPoints(LoyaltyProgram, Partner)
	
	If Not ValueIsFilled(LoyaltyProgram) Or Not ValueIsFilled(Partner) Then
		Return 0;
	EndIf;
	
	BalanceBonusPoints = BonusPointsServer.BalancesAndRegisteredRecordsOfBonusPoints(LoyaltyProgram, Partner);
	
	Return BalanceBonusPoints[0].Sum;
	
EndFunction

// Returns the client's sales turnover
//
// Parameters: 
//  LoyaltyCard - DefinedType.LoyaltyCardOfLoyaltyServer
//
// Returns:
//  Number - Customer sales turnover
//
Function GetTurnoverOfCustomerSales(LoyaltyCard)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DimensionKeysOfAccountingByPartners.Partner AS Partner,
	|	DimensionKeysOfAccountingByPartners.Ref AS PartnerAnalyticsKey
	|INTO PartnersKeysAnalyst
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|		ON LoyaltyCards.Partner = DimensionKeysOfAccountingByPartners.Partner
	|			AND LoyaltyCards.Ref = &LoyaltyCard
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS SumTurnover
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers( , , ,
	|		AccountingDimensionByPartners IN
	|			(SELECT
	|				PartnersKeysAnalyst.PartnerAnalyticsKey
	|			FROM
	|				PartnersKeysAnalyst AS PartnersKeysAnalyst)) AS RevenueAndCostOfSalesTurnover
	|";
	Query.SetParameter("LoyaltyCard", LoyaltyCard);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.SumTurnover;
	Else
		Return 0;
	EndIf;
	
EndFunction

Function TypeOfSearchByCode(Code)
	
	FindType = "";
	
	If Code = 1 Then
		FindType = "Клиент"; //@NON-NLS-1
	ElsIf Code = 2 Then
		FindType = "КодКарты"; //@NON-NLS-1
	ElsIf Code = 3 Then
		FindType = "Телефон"; //@NON-NLS-1
	ElsIf Code = 4 Then
		FindType = "АдресЭП"; //@NON-NLS-1
	EndIf;
	
	Return FindType;
	
EndFunction

// Complements the serialized structure with message data
//
// Parameters:
//  SerializedDiscountStructure - See SerializeCalculationResult
//  CashRegisterReceiptObject - DocumentObject.CashRegisterReceipt
//
Procedure AddMessagesToDiscountStructure(SerializedDiscountStructure, CashRegisterReceiptObject)
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(CashRegisterReceiptObject);
	
	ArrayOfMessages = New Array;
	
	For Each MessageString In TheStructureOfTheMessages.Messages Do
	
		StringStructure = New Structure;
		
		StringStructure.Insert("AfterSale", False);
		StringStructure.Insert("MessageText", 
			Common.ObjectAttributeValue(MessageString.DiscountMarkup, "MessageText"));
		
		ArrayOfMessages.Add(StringStructure);
	
	EndDo;
	
	SerializedDiscountStructure.Insert("Messages", ArrayOfMessages);
	
EndProcedure

// Complements the serialized structure with bonus data
//
// Parameters:
//  SerializedDiscountStructure - See SerializeCalculationResult
//  CalculationResult2 - Structure
//  CashRegisterReceiptObject - DocumentObject.CashRegisterReceipt
//
Procedure SupplementStructureOfDiscountsWithTableOfBonuses(SerializedDiscountStructure, CalculationResult2, CashRegisterReceiptObject)
	
	ArrayOfBonuses = New Array;
	
	FilterCalculationResult2 = New Structure("DiscountApplicationMethod", Enums.DiscountMarkupApplicationMethods.GrantBonusPoints);
	DiscountsMarkups = CalculationResult2.TableDiscountsMarkups.FindRows(FilterCalculationResult2);
	
	For Each BonusElement In DiscountsMarkups Do
		
		StringStructure = New Structure;
		
		BonusProgram = Common.ObjectAttributeValue(BonusElement.DiscountMarkup, "LoyaltyProgram");
		
		FilterBonuses = New Structure("LoyaltyProgram", BonusProgram);
		Bonuses      = CashRegisterReceiptObject.BonusPoints.FindRows(FilterBonuses);
		
		If Bonuses.Count() = 0 Then
			Return;
		EndIf;
		
		LinkStructureDiscountMarkup     = GetLinkStructure(BonusElement.DiscountMarkup);
		LinkStructureBonusProgram = GetLinkStructure(BonusProgram);
		
		StringStructure.Insert("KeyRelation",   BonusElement.ConnectionKey);
		StringStructure.Insert("LineUID",       BonusElement.RowID);
		StringStructure.Insert("Discount",      LinkStructureDiscountMarkup);
		StringStructure.Insert("BonusProgramm", LinkStructureBonusProgram);
		StringStructure.Insert("BonusCount",    BonusElement.Sum);
		StringStructure.Insert("AccuralDate",   Bonuses[0].AccrualDate);
		StringStructure.Insert("WriteOffDate",  Bonuses[0].DateOfDeduction);
		
		ArrayOfBonuses.Add(StringStructure);
	
	EndDo;
	
	SerializedDiscountStructure.Insert("BonusesToAccrue", ArrayOfBonuses);
	
EndProcedure

// Complements the serialized structure with discount data
//
// Parameters:
//  SerializedDiscountStructure - See SerializeCalculationResult
//  TableOfMarkupDiscounts - ValueTable
//
Procedure SupplementDiscountStructureWithMarkupDiscountTable(SerializedDiscountStructure, TableOfMarkupDiscounts)
	
	ArrayOfDiscountMargins = New Array;
	
	For Each DiscountMarkUpLine_ In TableOfMarkupDiscounts Do
	
		StringStructure = New Structure; 
		RefStructure = GetLinkStructure(DiscountMarkUpLine_.DiscountMarkup);
		
		StringStructure.Insert("KeyRelation", DiscountMarkUpLine_.ConnectionKey);
		StringStructure.Insert("Discount", RefStructure);
		StringStructure.Insert("DiscountValue", Common.ObjectAttributeValue(DiscountMarkUpLine_.DiscountMarkup, "DiscountMarkupValue"));
		StringStructure.Insert("Amount", DiscountMarkUpLine_.Sum);
		StringStructure.Insert("MinimalPriceRestriction", False);
		StringStructure.Insert("Comment", "");
		StringStructure.Insert("LineUID", DiscountMarkUpLine_.RowID);
		
		ArrayOfDiscountMargins.Add(StringStructure);
	
	EndDo;
	
	SerializedDiscountStructure.Insert("DiscountsList", ArrayOfDiscountMargins);
	
EndProcedure

// Parameters:
//	IncomingParameters - See FillInTableOfManagedDiscounts.CalculationParameters
// Returns:
//	Structure:
//	*UseSelections - Boolean - If False, the remaining properties are not subject to consideration
//	*Store - CatalogRef.Warehouses - The warehouse for which discounts are intended
//	*Client - Undefined - not used in the current version
//	*MaxMarkupPercentage - Number - 
//	*MaxDiscountPercentage - Number - 
//	*LoyaltyCard - CatalogRef.LoyaltyCards - 
Function FillInTableOfManagedDiscountsCalculationParameters(Val IncomingParameters = Undefined)
	
	Result = New Structure;
	Result.Insert("UseSelections", False);
	Result.Insert("Store", PredefinedValue("Catalog.Warehouses.EmptyRef"));
	Result.Insert("Client", Undefined);
	Result.Insert("MaxMarkupPercentage", 0);
	Result.Insert("MaxDiscountPercentage", 0);
	//The result.Insert("Client ID", "");
	//The result.Insert("Unique Card Identifier", "");
	Result.Insert("LoyaltyCard", PredefinedValue("Catalog.LoyaltyCards.EmptyRef"));
	
	If TypeOf(IncomingParameters) = Type("Structure") Then
		NameProperty = "UseSelections";
		If IncomingParameters.Property(NameProperty) And IncomingParameters[NameProperty] = True Then
			Result[NameProperty] = True;
		Else
			Result[NameProperty] = False;
			
			Return Result;
			
		EndIf;
		
		NameProperty = "Store";
		PropertyValue = Undefined;
		If IncomingParameters.Property(NameProperty, PropertyValue) Then
			Try
				ReferenceID = New UUID(PropertyValue);
				ShopLink =  Catalogs.Warehouses.GetRef(ReferenceID);
				Result[NameProperty] = ShopLink;
			Except
				ErrorInfo = ErrorInfo();
				ErrorDescriptionTemplate = NStr(
					"vi = 'Lỗi nhận phần tử %1 theo ID(%2):
					|""%3""';
					|ru = 'Ошибка получения элемента %1 по идентификатору(%2):
					|""%3""';
					|en = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""'; fa = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|it = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|pl = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|tr = '%1 öğesinin (%2) tanımlayıcısına göre alımında hata:
					|""%3""'", Common.DefaultLanguageCode());
				LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					NameProperty,
					PropertyValue,
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
				WriteLogEvent(
					"LoyaltyServerDataProviderTM.FillInTableOfManagedDiscountsCalculationParameters",
					EventLogLevel.Error,,,
					LongDesc);
			EndTry;
		EndIf;
		
		NameProperty = "LoyaltyCard";
		PropertyValue = Undefined;
		SearchForCardByNumber = False;
		If IncomingParameters.Property("UniqueCardId", PropertyValue)
			And ValueIsFilled(PropertyValue) Then
			Try
				ReferenceID = New UUID(PropertyValue);
				LoyaltyCardLink =  Catalogs.LoyaltyCards.GetRef(ReferenceID);
				Result[NameProperty] = LoyaltyCardLink;
			Except
				ErrorInfo = ErrorInfo();
				ErrorDescriptionTemplate = NStr(
					"vi = 'Lỗi nhận phần tử %1 theo ID(%2):
					|""%3""';
					|ru = 'Ошибка получения элемента %1 по идентификатору(%2):
					|""%3""';
					|en = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""'; fa = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|it = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|pl = 'An error occurred when receiving the %1 item by ID (%2):
					|""%3""';
					|tr = '%1 öğesinin (%2) tanımlayıcısına göre alımında hata:
					|""%3""'", Common.DefaultLanguageCode());
				LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorDescriptionTemplate,
					NameProperty,
					PropertyValue,
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
				WriteLogEvent(
					"LoyaltyServerDataProviderTM.FillInTableOfManagedDiscountsCalculationParameters",
					EventLogLevel.Error,,,
					LongDesc);
			EndTry;
		ElsIf IncomingParameters.Property("IdOfClientSCard", PropertyValue) Then
			SearchForCardByNumber = True;
		EndIf;
		If SearchForCardByNumber Then
			Query = New Query;
			Query.Parameters.Insert("CardNumber", PropertyValue);
			Query.Text = 
			"SELECT
			|	MAX(LoyaltyCards.Ref) AS Ref,
			|	LoyaltyCards.Barcode AS Barcode,
			|	COUNT(DISTINCT LoyaltyCards.Ref) AS TotalByNumber
			|FROM
			|	Catalog.LoyaltyCards AS LoyaltyCards
			|WHERE
			|	LoyaltyCards.Barcode = &CardNumber
			|
			|GROUP BY
			|	LoyaltyCards.Barcode";
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Result[NameProperty] = Selection.Ref;
			EndIf;
		EndIf;
		
	EndIf;
	Return Result;
EndFunction

#EndRegion