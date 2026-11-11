
#Region Public

// The function returns a structure with the loyalty card data.
//
// Parameters:
//  LoyaltyCard - CatalogRef.LoyaltyCards - Loyalty card.
//  CheckAvailability - Boolean - To check the availability of data.
//
// Returns:
//  Structure - Loyalty card details, See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
Function GetLoyaltyCardDetails(LoyaltyCard, CheckAvailability = True) Export
	
	SetPrivilegedMode(True);
	
	MapDataStructure = LoyaltyCardsServer.InitializeLoyaltyCardData();
	
	Query = New Query(
	"SELECT
	|	LoyaltyCards.Ref                         AS Ref,
	|	LoyaltyCards.Description                   AS Description,
	|	LoyaltyCards.Owner                       AS CardKind,
	|	LoyaltyCards.Status                         AS Status,
	|	LoyaltyCards.Owner.ValidityStartDate    AS ValidityStartDate,
	|	LoyaltyCards.Owner.ValidityEndDate AS ValidityEndDate,
	|	LoyaltyCards.Partner                        AS Partner,
	|	Partners.LegalEntityIndividual          AS LegalEntityIndividual,
	|	Partners.Presentation      AS PartnerPresentation,
	|	Partners.DescriptionFull AS Fiopartner,
	|	Partners.BirthDate       AS PartnerSDateOfBirth,
	|	Partners.Gender                AS PartnerSGender,
	|	LoyaltyCards.Counterparty                     AS Counterparty,
	|	LoyaltyCards.Terms                     AS Terms,
	|	LoyaltyCards.Barcode                       AS Barcode,
	|	LoyaltyCards.MagneticCode                   AS MagneticCode
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Partners.Ref = LoyaltyCards.Partner
	|WHERE
	|	LoyaltyCards.Ref = &Ref");
	
	Query.SetParameter("Ref", LoyaltyCard);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillPropertyValues(MapDataStructure, Selection);
	EndIf;
	
	If CheckAvailability Then
		
		SetPrivilegedMode(False);
		
		If AccessRight("Read", Metadata.Catalogs.Partners)
			And AccessRight("Read", Metadata.Catalogs.Counterparties)
			And AccessRight("Read", Metadata.Catalogs.TermsOfSale) Then
		
			Query = New Query(
			"SELECT ALLOWED
			|	Partners.Ref
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	Partners.Ref = &Partner
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	Counterparties.Ref
			|FROM
			|	Catalog.Counterparties AS Counterparties
			|WHERE
			|	Counterparties.Ref = &Counterparty
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	TermsOfSale.Ref
			|FROM
			|	Catalog.TermsOfSale AS TermsOfSale
			|WHERE
			|	TermsOfSale.Ref = &Terms
			|");
			
			Query.SetParameter("Partner",    MapDataStructure.Partner);
			Query.SetParameter("Counterparty", MapDataStructure.Counterparty);
			Query.SetParameter("Terms", MapDataStructure.Terms);
			
			Result = Query.ExecuteBatch();
			
			If ValueIsFilled(MapDataStructure.Partner) Then
				MapDataStructure.PartnerAvailable = Not Result[0].IsEmpty();
			EndIf;
			If ValueIsFilled(MapDataStructure.Counterparty) Then
				MapDataStructure.CounterpartyAvailable = Not Result[1].IsEmpty();
			EndIf;
			If ValueIsFilled(MapDataStructure.Terms) Then
				MapDataStructure.AgreementAvailable = Not Result[2].IsEmpty();
			EndIf;
		
		Else
			
			MapDataStructure.PartnerAvailable    = False;
			MapDataStructure.CounterpartyAvailable = False;
			MapDataStructure.AgreementAvailable = False;
			
		EndIf;
		
	EndIf;
	
	Return MapDataStructure;
	
EndFunction

#Region SearchForLoyaltyCards

// The function searches for loyalty cards based on data received from
// the magnetic card reader.
//
// Parameters:
//  Data - Array - Array of data received from the magnetic card reader.
//
// Returns:
//  Structure - with properties:
//   * RegisteredLoyaltyCards   - Array of See LoyaltyCardsServer.InitializeLoyaltyCardData
//   * NotRegisteredLoyaltyCards - Array of See LoyaltyCardsServer.InitializeLoyaltyCardData
//
Function FindLoyaltyCardsBasedOnMagneticCardReaderData(Data) Export
	
	SetPrivilegedMode(True);
	
	RegisteredLoyaltyCards = New Array;
	NotRegisteredLoyaltyCards = New Array;
	
	DecryptedData = Data[1][3];
	If DecryptedData <> Undefined Then
		For Each Structure In DecryptedData Do
			
			MagneticStripeCardTemplate = Structure.Template;
			CardCode             = Data[0];
			For Each FieldData In Structure.TrackData Do
				If FieldData.Field = Enums.MagneticStripeCardTemplateFields.Code Then
					CardCode = FieldData.Simple;
					Break;
				EndIf;
			EndDo;
			
			Query = New Query(
			"SELECT DISTINCT
			|	TemplatesOfLoyaltyCardCodes.Ref                                              AS Ref,
			|	TemplatesOfLoyaltyCardCodes.Ref.Status                                       AS Status,
			|	TemplatesOfLoyaltyCardCodes.Ref.Personalized                            AS Personalized,
			|	TemplatesOfLoyaltyCardCodes.Ref.CardType                                     AS CardType,
			|	TemplatesOfLoyaltyCardCodes.Ref.AllowAutoRegistrationAtFirstReading AS AllowAutoRegistrationAtFirstReading,
			|	TemplatesOfLoyaltyCardCodes.Ref.ValidityStartDate                           AS ValidityStartDate,
			|	TemplatesOfLoyaltyCardCodes.Ref.ValidityEndDate                        AS ValidityEndDate,
			|	TemplatesOfLoyaltyCardCodes.Ref.Organization                                  AS Organization
			|INTO TypesOfMaps
			|FROM
			|	Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
			|WHERE
			|	TemplatesOfLoyaltyCardCodes.StartOfMagneticCodeRange  <= &CardCode
			|	AND TemplatesOfLoyaltyCardCodes.EndOfMagneticCodeRange >= &CardCode
			|	AND TemplatesOfLoyaltyCardCodes.MagneticCodeLength           = &CodeLength
			|	AND TemplatesOfLoyaltyCardCodes.MagneticStripeCardTemplate          = &MagneticStripeCardTemplate
			|	AND TemplatesOfLoyaltyCardCodes.Ref.Status                 = VALUE(Enum.StatusesOfLoyaltyCardKinds.Valid)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	LoyaltyCards.Ref       AS Ref,
			|	LoyaltyCards.Description AS Description,
			|	LoyaltyCards.Barcode     AS Barcode,
			|	LoyaltyCards.MagneticCode AS MagneticCode,
			|	LoyaltyCards.Partner      AS Partner,
			|	LoyaltyCards.Counterparty   AS Counterparty,
			|	LoyaltyCards.Terms   AS Terms,
			|	LoyaltyCards.Status       AS Status,
			|	
			|	LoyaltyCards.Owner                                              AS CardKind,
			|	LoyaltyCards.Owner.Status                                       AS CardKindStatus,
			|	LoyaltyCards.Owner.ValidityStartDate                           AS ValidityStartDate,
			|	LoyaltyCards.Owner.ValidityEndDate                        AS ValidityEndDate,
			|	LoyaltyCards.Owner.Personalized                            AS Personalized,
			|	LoyaltyCards.Owner.CardType                                     AS CardType,
			|	LoyaltyCards.Owner.AllowAutoRegistrationAtFirstReading AS AllowAutoRegistrationAtFirstReading,
			|	TypesOfMaps.Organization                                                  AS Organization
			|INTO LoyaltyCards
			|FROM
			|	Catalog.LoyaltyCards AS LoyaltyCards
			|		INNER JOIN TypesOfMaps
			|		ON TypesOfMaps.Ref = LoyaltyCards.Owner
			|		 AND LoyaltyCards.MagneticCode = &CardCode
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	1                            AS Order,
			|	LoyaltyCards.Ref       AS Ref,
			|	LoyaltyCards.Description AS Description,
			|	LoyaltyCards.Barcode     AS Barcode,
			|	LoyaltyCards.MagneticCode AS MagneticCode,
			|	LoyaltyCards.Partner      AS Partner,
			|	LoyaltyCards.Counterparty   AS Counterparty,
			|	LoyaltyCards.Terms   AS Terms,
			|	LoyaltyCards.Status       AS Status,
			|	
			|	LoyaltyCards.CardKind                                     AS CardKind,
			|	LoyaltyCards.CardKindStatus                              AS CardKindStatus,
			|	LoyaltyCards.ValidityStartDate                           AS ValidityStartDate,
			|	LoyaltyCards.ValidityEndDate                        AS ValidityEndDate,
			|	LoyaltyCards.Personalized                            AS Personalized,
			|	LoyaltyCards.CardType                                     AS CardType,
			|	LoyaltyCards.AllowAutoRegistrationAtFirstReading AS AllowAutoRegistrationAtFirstReading,
			|	LoyaltyCards.Organization  AS Organization
			|FROM
			|	LoyaltyCards
			|
			|UNION ALL
			|
			|SELECT
			|	2                                                         AS Order,
			|	VALUE(Catalog.LoyaltyCards.EmptyRef)         AS Ref,
			|	""""                                                      AS Description,
			|	""""                                                      AS Barcode,
			|	&CardCode                                                 AS MagneticCode,
			|	VALUE(Catalog.Partners.EmptyRef)                AS Partner,
			|	VALUE(Catalog.Counterparties.EmptyRef)             AS Counterparty,
			|	VALUE(Catalog.TermsOfSale.EmptyRef)    AS Terms,
			|	VALUE(Enum.LoyaltyCardStatuses.EmptyRef) AS Status,
			|	
			|	TypesOfMaps.Ref                                       AS CardKind,
			|	TypesOfMaps.Status                                       AS CardKindStatus,
			|	TypesOfMaps.ValidityStartDate                           AS ValidityStartDate,
			|	TypesOfMaps.ValidityEndDate                        AS ValidityEndDate,
			|	TypesOfMaps.Personalized                            AS Personalized,
			|	TypesOfMaps.CardType                                     AS CardType,
			|	TypesOfMaps.AllowAutoRegistrationAtFirstReading AS AllowAutoRegistrationAtFirstReading,
			|	TypesOfMaps.Organization                                  AS Organization
			|FROM
			|	TypesOfMaps AS TypesOfMaps
			|WHERE
			|	(NOT TypesOfMaps.Ref IN
			|				(SELECT DISTINCT
			|					T.CardKind
			|				FROM
			|					LoyaltyCards AS T))
			|ORDER BY
			|	Order ASC
			|");
			
			Query.SetParameter("MagneticStripeCardTemplate", MagneticStripeCardTemplate);
			Query.SetParameter("CardCode",             CardCode);
			Query.SetParameter("CodeLength",            StrLen(CardCode));
			
			Result = Query.Execute();
			Selection = Result.Select();
			While Selection.Next() Do
			
				If ValueIsFilled(Selection.Ref) Then
					NewRow = LoyaltyCardsServer.InitializeLoyaltyCardData();
					FillPropertyValues(NewRow, Selection);
					RegisteredLoyaltyCards.Add(NewRow);
				Else
					NewRow = LoyaltyCardsServer.InitializeLoyaltyCardData();
					FillPropertyValues(NewRow, Selection);
					NotRegisteredLoyaltyCards.Add(NewRow);
				EndIf;
				
			EndDo;
			
		EndDo;
	EndIf;
	
	ReturnValue = New Structure("RegisteredLoyaltyCards, NotRegisteredLoyaltyCards");
	ReturnValue.RegisteredLoyaltyCards   = RegisteredLoyaltyCards;
	ReturnValue.NotRegisteredLoyaltyCards = NotRegisteredLoyaltyCards;
	
	Return ReturnValue;
	
EndFunction

// The function searches for loyalty cards by barcode.
//
// Parameters:
//  Barcode - String - barcode.
//
// Returns:
//  Structure - with properties:
//   * RegisteredLoyaltyCards   - ValueTable - Details of registered loyalty cards,
//                                           See LoyaltyCardsServer.InitializeLoyaltyCardData.
//   * NotRegisteredLoyaltyCards - ValueTable - Data of unregistered loyalty cards,
//                                           See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
Function FindLoyaltyCardsByBarcode(Barcode) Export
	
	Return LoyaltyCardsServer.FindLoyaltyCards(Barcode, Enums.CardCodeTypes.Barcode);
	
EndFunction

#EndRegion

#EndRegion
