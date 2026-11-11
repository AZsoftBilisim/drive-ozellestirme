
#Region Public

// The procedure is called from the list forms when the magnetic code is received.
// Searches for a loyalty card in the database and calls the "read Loyalty card" alert
// for the owner form.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  Data - Array - Array of data received from the magnetic card reader.
//
Procedure ProcessMagneticCardReaderData(Form, Data) Export
	
	LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsBasedOnMagneticCardReaderData(Data);
	
	If LoyaltyCards.RegisteredLoyaltyCards.Count() > 0 Then
		
		If LoyaltyCards.RegisteredLoyaltyCards.Count() = 1 Then
			
			SelectedLoyaltyCard = LoyaltyCards.RegisteredLoyaltyCards[0]; // See LoyaltyCardsServer.InitializeLoyaltyCardData
			
			Notify(
				"LoyaltyCardIsRead",
				New Structure("LoyaltyCard, OwnerForm", SelectedLoyaltyCard.Ref, Form.UUID),
				Undefined);
			
		Else
			
			OpenForm(
				"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
				New Structure("CardCode, CodeType", Data, PredefinedValue("Enum.CardCodeTypes.MagneticCode")),
				Form,
				Form.UUID);
			
		EndIf;
		
	ElsIf LoyaltyCards.NotRegisteredLoyaltyCards.Count() > 0 Then
		
		OpenForm(
			"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
			New Structure("CardCode, CodeType", Data, PredefinedValue("Enum.CardCodeTypes.MagneticCode")),
			Form,
			Form.UUID);
		
	EndIf;
	
EndProcedure

// The procedure is called from the list forms when the barcode is received.
// Searches for a loyalty card in the database and calls the "read Loyalty card" alert
// for the owner form.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  Barcodes - Array, String - Barcodes.
//
Procedure ProcessBarcodes(Form, Barcodes) Export
	
	If TypeOf(Barcodes) = Type("Array") Then
		ArrayOfBarcodes = Barcodes;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(Barcodes);
	EndIf;
	
	If ArrayOfBarcodes.Count() = 1 Then
		
		LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(ArrayOfBarcodes[0].Barcode);
		
		If LoyaltyCards.RegisteredLoyaltyCards.Count() > 0 Then
			
			If LoyaltyCards.RegisteredLoyaltyCards.Count() = 1 Then
				
				Notify(
					"LoyaltyCardIsRead",
					New Structure("LoyaltyCard, OwnerForm", LoyaltyCards.RegisteredLoyaltyCards[0].Ref, Form.UUID),
					Undefined);
				
			Else
				
				OpenForm(
					"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
					New Structure("CardCode, CodeType", ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode")),
					Form,
					Form.UUID);
				
			EndIf;
			
		ElsIf LoyaltyCards.NotRegisteredLoyaltyCards.Count() > 0 Then
			
			OpenForm(
				"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
				New Structure("CardCode, CodeType", ArrayOfBarcodes[0].Barcode, PredefinedValue("Enum.CardCodeTypes.Barcode")),
				Form,
				Form.UUID);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// When you start selecting a loyalty card
//
// Parameters:
//  Item - FormItems - form element.
//  StandardProcessing - Boolean - Standard treatment.
//  Partner - CatalogRef.Partners - Partner.
//  DocumentDate - Date - document date.
//  Organization - CatalogRef.Companies, Undefined - Organization.
//  AdditionalParameters - Structure - additional parameters for opening the form.
//
Procedure StartSelectingLoyaltyCard(Item, StandardProcessing, Partner, DocumentDate, Organization = Undefined, AdditionalParameters = Undefined) Export
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DocumentDate", DocumentDate);
	OpeningParameters.Insert("Partner",       Partner);
	OpeningParameters.Insert("Organization",   Organization);
	
	If AdditionalParameters <> Undefined Then
		For Each KeyAndValue In AdditionalParameters Do
			OpeningParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;

	OpenForm(
		"Catalog.LoyaltyCards.Form.ChoiceForm",
		OpeningParameters,
		Item);
	
EndProcedure

#Region QuestionnairePrintCommands

// The procedure prints the questionnaire in the "Microsoft Word" format"
//
// Parameters:
//  CommandDetails - Structure - command description.
//
Procedure PrintingMicrosoftWordQuestionnaire(CommandDetails) Export
	
	LoyaltyCardsLocalizationClient.PrintingMicrosoftWordQuestionnaire(CommandDetails);
	
EndProcedure

#EndRegion

#EndRegion

