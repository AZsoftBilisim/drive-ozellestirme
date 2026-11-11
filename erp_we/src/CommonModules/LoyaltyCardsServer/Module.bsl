
#Region Public

// The procedure creates a partner with 
// the name "loyalty card Holder" based
// on the passed structure with the loyalty card data.
//
// Parameters:
//  MapDataStructure - Structure - Loyalty card details, See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
// Returns:
//  CatalogRef.Partners - Partner.
//
Function CreateLoyaltyCardHolderPartner(MapDataStructure) Export
	
	PartnerObject_ = Catalogs.Partners.CreateItem();
	If MapDataStructure.Fiopartner = Undefined Then
		PartnerObject_.Description = NStr("vi = 'Người sở hữu thẻ khách hàng thân thiết';
											|ru = 'Держатель карты лояльности';
											|en = 'Loyalty card holder'; fa = 'Loyalty card holder';
											|it = 'Proprietario delle carte di fedeltà';
											|pl = 'Posiadacz karty lojalnościowej';
											|tr = 'Sadakat kartı sahibi'")
		                             + ?(ValueIsFilled(MapDataStructure.Barcode), StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', Mã vạch: %1';
																																				|ru = ', Штрихкод: %1';
																																				|en = ', Barcode: %1'; fa = ', Barcode: %1';
																																				|it = ', Codice a barre: %1';
																																				|pl = ', Kod kreskowy: %1';
																																				|tr = ', Barkod: %1'"), MapDataStructure.Barcode), "")
		                             + ?(ValueIsFilled(MapDataStructure.MagneticCode), StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ', Mã thẻ từ: %1';
																																					|ru = ', Магнитный код: %1';
																																					|en = ', Magnetic code: %1'; fa = ', Magnetic code: %1';
																																					|it = ', Codice magnetico: %1';
																																					|pl = ', Kod magnetyczny: %1';
																																					|tr = ', Manyetik kod: %1'"), MapDataStructure.MagneticCode), "");
	Else
		PartnerObject_.Description = MapDataStructure.Fiopartner;
	EndIf;
	PartnerObject_.DescriptionFull = PartnerObject_.Description;
	PartnerObject_.LegalEntityIndividual          = Enums.IndividualCompany.Person_;
	PartnerObject_.Comment        = NStr("vi = 'Cần điền dữ liệu về khách hàng thông qua phiếu đăng ký.';
										|ru = 'Данные о клиенте необходимо заполнить при помощи регистрационной анкеты.';
										|en = 'Use an application form to fill out the customer data.'; fa = 'Use an application form to fill out the customer data.';
										|it = 'I dati del cliente devono essere compilati utilizzando il modulo di iscrizione.';
										|pl = 'Dane o kliencie należy wypełnić za pomocą ankiety rejestracyjnej.';
										|tr = 'Müşteri verileri, kayıt soru formu kullanılarak doldurulmalıdır.'");
	PartnerObject_.Client             = True;
	PartnerObject_.MainManager   = Users.CurrentUser();
	PartnerObject_.RegistrationDate    = CurrentSessionDate();
	
	If AccessManagement.LimitAccessAtRecordLevel() 
		And GetFunctionalOption("UsePartnerAccessGroups") Then
		
		If MapDataStructure.Property("AccessGroup") And ValueIsFilled(MapDataStructure.AccessGroup) Then
			PartnerObject_.AccessGroup = MapDataStructure.AccessGroup;				
		Else
			PermittedGroups = AccessManagement.AccessValuesGroupsAllowingAccessValuesChange(Type("CatalogRef.Partners"), True);
			If PermittedGroups.Count() > 0 Then
				PartnerObject_.AccessGroup = PermittedGroups[0];
			EndIf;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(MapDataStructure.PartnerSDateOfBirth) Then
		PartnerObject_.BirthDate = MapDataStructure.PartnerSDateOfBirth;
	EndIf;
		
	If ValueIsFilled(MapDataStructure.PhoneNumber) Then
		ContactsManager.AddContactInformation(PartnerObject_,
			MapDataStructure.PhoneNumber,
			PredefinedValue("Catalog.ContactInformationKinds.PartnerSPhoneNumber"));
	EndIf;
	
	If ValueIsFilled(MapDataStructure.Email) Then
		ContactsManager.AddContactInformation(PartnerObject_,
			MapDataStructure.Email,
			PredefinedValue("Catalog.ContactInformationKinds.EmailPartner_"));
	EndIf;
		
	PartnerObject_.Write();
	
	If GetFunctionalOption("UsePartnersAsCounterparties")
		Or MapDataStructure.CreateCounterparty Then
		
		CounterpartyObject = Catalogs.Counterparties.CreateItem();
		CounterpartyObject.Description       = PartnerObject_.Description;
		CounterpartyObject.DescriptionFull = PartnerObject_.Description;
		CounterpartyObject.LegalEntityIndividual          = Enums.LegalEntityIndividual.Person;
		CounterpartyObject.Partner            = PartnerObject_.Ref;
		
		If ValueIsFilled(MapDataStructure.PhoneNumber) Then
			ContactsManager.AddContactInformation(CounterpartyObject,
				MapDataStructure.PhoneNumber,
				PredefinedValue("Catalog.ContactInformationKinds.CounterpartySPhoneNumber"));
		EndIf;
		
		If ValueIsFilled(MapDataStructure.Email) Then
			ContactsManager.AddContactInformation(CounterpartyObject,
				MapDataStructure.Email,
				PredefinedValue("Catalog.ContactInformationKinds.EmailCounterparty_"));
		EndIf;
			
		CounterpartyObject.Write();
		
	EndIf;
	
	Return PartnerObject_.Ref;
	
EndFunction

// The procedure writes a loyalty card to the database based
// on the passed structure with the loyalty card data, and also creates a partner with 
// the name "loyalty card Holder".
//
// Parameters:
//  MapDataStructure - Structure - Loyalty card details, See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
// Returns:
//  CatalogRef.LoyaltyCards - Loyalty card.
//
Function CreatePartnerAndRegisterLoyaltyCard(MapDataStructure) Export
	
	SetPrivilegedMode(True);
	
	MapDataStructure.Partner    = CreateLoyaltyCardHolderPartner(MapDataStructure);
	MapDataStructure.Counterparty = Undefined;
	MapDataStructure.Terms = Undefined;
	
	Return RegisterLoyaltyCard(MapDataStructure)
	
EndFunction

// Cancel your loyalty card.
//
// Parameters:
//  LoyaltyCard - CatalogRef.LoyaltyCards - Loyalty card.
//
Procedure CancelLoyaltyCard(LoyaltyCard) Export
	
	SetPrivilegedMode(True);
	
	Map_Object = LoyaltyCard.GetObject();
	Map_Object.Status = Enums.LoyaltyCardStatuses.Cancelled__;
	Map_Object.Write();
	
EndProcedure

// The procedure writes a loyalty card to the database based
// on the passed structure with the loyalty card data.
//
// Parameters:
//  MapDataStructure - Structure - Loyalty card details, See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
// Returns:
//  CatalogRef.LoyaltyCards - Loyalty card.
//
Function RegisterLoyaltyCard(MapDataStructure) Export
	
	SetPrivilegedMode(True);
	
	Map_Object = Catalogs.LoyaltyCards.CreateItem();
	
	Map_Object.Barcode     = MapDataStructure.Barcode;
	Map_Object.MagneticCode = MapDataStructure.MagneticCode;
	
	Map_Object.Owner   = MapDataStructure.CardKind;
	
	Map_Object.Partner    = MapDataStructure.Partner;
	Map_Object.Counterparty = MapDataStructure.Counterparty;
	Map_Object.Terms = MapDataStructure.Terms;
	
	Map_Object.Status = Enums.LoyaltyCardStatuses.Valid;
	
	Map_Object.Description = String(Map_Object.Owner)
	                         + ?(ValueIsFilled(Map_Object.Barcode), " " + String(Map_Object.Barcode), "")
	                         + ?(ValueIsFilled(Map_Object.MagneticCode), " " + String(Map_Object.MagneticCode), "");
	Map_Object.Write();
	
	Return Map_Object.Ref;
	
EndFunction

// The function returns an empty data structure for loyalty cards
//
// Returns:
// 	Structure
//
Function InitializeLoyaltyCardData() Export
	
	StructureOfData = New Structure;
	StructureOfData.Insert("Barcode");
	StructureOfData.Insert("MagneticCode");
	StructureOfData.Insert("Ref");
	StructureOfData.Insert("CardKind");
	StructureOfData.Insert("CardType");
	StructureOfData.Insert("Personalized");
	StructureOfData.Insert("AllowAutoRegistrationAtFirstReading");
	StructureOfData.Insert("Partner");
	StructureOfData.Insert("Counterparty");
	StructureOfData.Insert("Terms");
	StructureOfData.Insert("Status");
	StructureOfData.Insert("ValidityStartDate");
	StructureOfData.Insert("ValidityEndDate");
	StructureOfData.Insert("Organization");
	
	// Radar data
	StructureOfData.Insert("PartnerAvailable",    True);
	StructureOfData.Insert("AgreementAvailable", True);
	StructureOfData.Insert("CounterpartyAvailable", True);
	
	// Background information on the type of card
	StructureOfData.Insert("CardKindStatus");
	
	// Partner Reference information
	StructureOfData.Insert("LegalEntityIndividual");
	StructureOfData.Insert("Fiopartner");
	StructureOfData.Insert("PartnerSDateOfBirth");
	StructureOfData.Insert("PartnerSGender");
	StructureOfData.Insert("AccessGroup");
	StructureOfData.Insert("PhoneNumber");
	StructureOfData.Insert("Email");
	StructureOfData.Insert("CreateCounterparty", False);
	
	Return StructureOfData;
	
EndFunction

// The function returns the type of loyalty card code, if only it
// is used in loyalty card types.
//
// Returns:
//  EnumRef.CardCodeTypes, Undefined - The main type of loyalty card code.
//
Function GetMainTypeOfLoyaltyCardCode() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	LoyaltyCardKinds.CardType AS CardType
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds");
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Count = Selection.Count();
	If Count = 0 Then
		Return Undefined;
	ElsIf Count = 1 Then
		Selection.Next();
		If Selection.CardType = Enums.CardTypes.Barcode_ Then
			Return Enums.CardCodeTypes.Barcode;
		ElsIf Selection.CardType = Enums.CardTypes.Magnetic Then
			Return Enums.CardCodeTypes.MagneticCode;
		ElsIf Selection.CardType = Enums.CardTypes.Mixed Then
			Return Undefined;
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region SearchForLoyaltyCards

// The procedure returns the partner's loyalty card if they have only one.
//
// Parameters:
//  Partner - CatalogRef.Partners - Partner.
//
// Returns:
//  CatalogRef.LoyaltyCards, Undefined - Loyalty card.
//
Function GetPartnerSDefaultCard(Partner) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 2
	|	LoyaltyCards.Ref AS Ref
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Partner = &Partner");
	
	Query.SetParameter("Partner", Partner);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Count() = 1 Then
		Selection.Next();
		ReplacedCard = Selection.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// The function searches for types of loyalty cards that can have the specified code and code type.
//
// Parameters:
//  CardCode - String - Card code.
//  CodeType - EnumRef.CardCodeTypes - Type of map code.
//
// Returns:
//  Array - Array of links to types of loyalty cards.
//
Function GetPossibleTypesOfLoyaltyCardsByCardCode(CardCode, CodeType) Export
	
	SetPrivilegedMode(True);
	
	TypesOfMaps = New Array;
	
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		Query = New Query(
		"SELECT
		|	TemplatesOfLoyaltyCardCodes.Ref AS CardKind
		|FROM
		|	Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
		|WHERE
		|	  TemplatesOfLoyaltyCardCodes.StartOfMagneticCodeRange <= &CardCode
		|	AND TemplatesOfLoyaltyCardCodes.EndOfMagneticCodeRange  >= &CardCode
		|	AND TemplatesOfLoyaltyCardCodes.MagneticCodeLength = &CodeLength
		|	AND TemplatesOfLoyaltyCardCodes.Ref.Status = VALUE(Enum.StatusesOfLoyaltyCardKinds.Valid)
		|
		|ORDER BY
		|	StartOfMagneticCodeRange");
	Else
		Query = New Query(
		"SELECT
		|	TemplatesOfLoyaltyCardCodes.Ref AS CardKind
		|FROM
		|	Catalog.LoyaltyCardKinds.TemplatesOfLoyaltyCardCodes AS TemplatesOfLoyaltyCardCodes
		|WHERE
		|	TemplatesOfLoyaltyCardCodes.StartOfBarcodeRange <= &CardCode
		|	AND TemplatesOfLoyaltyCardCodes.EndOfBarcodeRange >= &CardCode
		|	AND TemplatesOfLoyaltyCardCodes.BarcodeLength = &CodeLength
		|	AND TemplatesOfLoyaltyCardCodes.Ref.Status = VALUE(Enum.StatusesOfLoyaltyCardKinds.Valid)
		|
		|ORDER BY
		|	TemplatesOfLoyaltyCardCodes.StartOfBarcodeRange");
	EndIf;

	Query.SetParameter("CardCode",  String(CardCode));
	Query.SetParameter("CodeLength", StrLen(String(CardCode)));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		TypesOfMaps.Add(Selection.CardKind);
	EndDo;
	
	Return TypesOfMaps;
	
EndFunction

// This function searches for loyalty cards.
//
// Parameters:
//  CardCode - String - String representation of the map code;
//  CodeType - EnumRef.CardCodeTypes - Type of loyalty card code.
//
// Returns:
//  Structure - Structure keys and properties:
//   * RegisteredLoyaltyCards - ValueTable - Data of registered loyalty cards:
//          ** Ref - CatalogRef.LoyaltyCards - link to the loyalty card reference element.
//          ** Barcode - String - Barcode of the loyalty card.
//          ** MagneticCode - String - Magnetic code.
//	        ** CardKind - CatalogRef.LoyaltyCardKinds - link to the loyalty card types reference element.
//	        ** CardType - EnumRef.CardCodeTypes - Type of loyalty card code.
//	        ** Personalized - Boolean - Indicates that the card is personalized.
//	        ** AllowAutoRegistrationAtFirstReading - Boolean - Indicates whether the card is automatically registered in the system.
//	        ** Partner - CatalogRef.Partners - The partner who was issued a loyalty card. 
//	        ** Counterparty - CatalogRef.Counterparties - The counterparty to whom the loyalty card was issued.
//	        ** Terms - CatalogRef.TermsOfSale - Link to the customer agreement reference list item.
//	        ** Status - EnumRef.LoyaltyCardStatuses - Link to list the status of the loyalty card.
//	        ** ValidityStartDate - Date - The date when the loyalty card starts working.
//	        ** ValidityEndDate - Date - Expiration date of the loyalty card.
//	        ** Organization - CatalogRef.Companies - The organization that issued the loyalty card on behalf of.
//	        ** PartnerAvailable - Boolean - Indicates whether the partner is available.
//	        ** AgreementAvailable - Boolean - Indicates whether the agreement is available.
//	        ** CounterpartyAvailable - Boolean - Indicates whether the counterparty is available.
//	        ** CardKindStatus - EnumRef.LoyaltyCardStatuses - Status of the loyalty card.
//	        ** LegalEntityIndividual - EnumRef - Specify the partner type.
//	        ** Fiopartner - String - Full name of the partner.
//	        ** PartnerSDateOfBirth - Date - Date of birth of the partner.
//	        ** PartnerSGender - EnumRef.GenderPersons - Gender of the partner who was issued the card.
//   * NotRegisteredLoyaltyCards - ValueTable - Data of unregistered loyalty cards:
//          ** Ref - CatalogRef.LoyaltyCards - link to the loyalty card reference element.
//          ** Barcode - String - Barcode of the loyalty card.
//          ** MagneticCode - String - Magnetic code.
//	        ** CardKind - CatalogRef.LoyaltyCardKinds - link to the loyalty card types reference element.
//	        ** CardType - EnumRef.CardCodeTypes - Type of loyalty card code.
//	        ** Personalized - Boolean - Indicates that the card is personalized.
//	        ** AllowAutoRegistrationAtFirstReading - Boolean - Indicates whether the card is automatically registered in the system.
//	        ** Partner - CatalogRef.Partners - The partner who was issued a loyalty card. 
//	        ** Counterparty - CatalogRef.Counterparties - The counterparty to whom the loyalty card was issued.
//	        ** Terms - CatalogRef.TermsOfSale - Link to the customer agreement reference list item.
//	        ** Status - EnumRef.LoyaltyCardStatuses - Link to list the status of the loyalty card.
//	        ** ValidityStartDate - Date - The date when the loyalty card starts working.
//	        ** ValidityEndDate - Date - Expiration date of the loyalty card.
//	        ** Organization - CatalogRef.Companies - The organization that issued the loyalty card on behalf of.
//	        ** PartnerAvailable - Boolean - Indicates whether the partner is available.
//	        ** AgreementAvailable - Boolean - Indicates whether the agreement is available.
//	        ** CounterpartyAvailable - Boolean - Indicates whether the counterparty is available.
//	        ** CardKindStatus - EnumRef.LoyaltyCardStatuses - Status of the loyalty card.
//	        ** LegalEntityIndividual - EnumRef - Specify the partner type.
//	        ** Fiopartner - String - Full name of the partner.
//	        ** PartnerSDateOfBirth - Date - Date of birth of the partner.
//	        ** PartnerSGender - EnumRef.GenderPersons - Gender of the partner who was issued the card.
//
Function FindLoyaltyCards(CardCode, CodeType) Export
	
	SetPrivilegedMode(True);
	
	RegisteredLoyaltyCards = New Array;
	NotRegisteredLoyaltyCards = New Array;
	
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
	|	&StartOfRangeCondition                    <= &CardCode
	|	AND &EndOfRangeCondition                   >= &CardCode
	|	AND &ConditionCodeLength                         = &CodeLength
	|	AND TemplatesOfLoyaltyCardCodes.Ref.Status <> VALUE(Enum.StatusesOfLoyaltyCardKinds.NotValid)
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
	|		ON TypesOfMaps.Ref  = LoyaltyCards.Owner
	|		 AND &NameOfMapCodeField = &CardCode
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
	|	LoyaltyCards.Organization                                  AS Organization
	|FROM
	|	LoyaltyCards
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                         AS Order,
	|	VALUE(Catalog.LoyaltyCards.EmptyRef)         AS Ref,
	|	""""                                                      AS Description,
	|	&Barcode                                                 AS Barcode,
	|	&MagneticCode                                             AS MagneticCode,
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
	
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		
		Query.Text = StrReplace(Query.Text,"&StartOfRangeCondition", "TemplatesOfLoyaltyCardCodes.StartOfMagneticCodeRange");
		Query.Text = StrReplace(Query.Text,"&EndOfRangeCondition",  "TemplatesOfLoyaltyCardCodes.EndOfMagneticCodeRange");
		Query.Text = StrReplace(Query.Text,"&ConditionCodeLength",       "TemplatesOfLoyaltyCardCodes.MagneticCodeLength");
		Query.Text = StrReplace(Query.Text,"&NameOfMapCodeField",        "LoyaltyCards.MagneticCode");
		
		Query.SetParameter("Barcode",     "");
		Query.SetParameter("MagneticCode", CardCode);
		
	Else
		
		Query.Text = StrReplace(Query.Text,"&StartOfRangeCondition", "TemplatesOfLoyaltyCardCodes.StartOfBarcodeRange");
		Query.Text = StrReplace(Query.Text,"&EndOfRangeCondition",  "TemplatesOfLoyaltyCardCodes.EndOfBarcodeRange");
		Query.Text = StrReplace(Query.Text,"&ConditionCodeLength",       "TemplatesOfLoyaltyCardCodes.BarcodeLength");
		Query.Text = StrReplace(Query.Text,"&NameOfMapCodeField",        "LoyaltyCards.Barcode");
		
		Query.SetParameter("Barcode",     CardCode);
		Query.SetParameter("MagneticCode", "");
		
	EndIf;
	
	Query.SetParameter("CardCode",  CardCode);
	Query.SetParameter("CodeLength", StrLen(CardCode));
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
	
		If ValueIsFilled(Selection.Ref) Then
			NewRow = InitializeLoyaltyCardData();
			FillPropertyValues(NewRow, Selection);
			RegisteredLoyaltyCards.Add(NewRow);
		Else
			NewRow = InitializeLoyaltyCardData();
			FillPropertyValues(NewRow, Selection);
			NotRegisteredLoyaltyCards.Add(NewRow);
		EndIf;
	
	EndDo;
	
	ReturnValue = New Structure("RegisteredLoyaltyCards, NotRegisteredLoyaltyCards");
	ReturnValue.RegisteredLoyaltyCards   = RegisteredLoyaltyCards;
	ReturnValue.NotRegisteredLoyaltyCards = NotRegisteredLoyaltyCards;
	
	Return ReturnValue;
	
EndFunction

// The function searches for loyalty cards using a magnetic code.
//
// Parameters:
//  MagneticCode - EnumRef.CardCodeTypes - Magnetic code.
//
// Returns:
//  Structure - structure with properties:
//   * RegisteredLoyaltyCards   - ValueTable - Details of registered loyalty cards,
//                                           See LoyaltyCardsServer.InitializeLoyaltyCardData.
//   * NotRegisteredLoyaltyCards - ValueTable - Data of unregistered loyalty cards,
//                                           See LoyaltyCardsServer.InitializeLoyaltyCardData.
//
Function FindLoyaltyCardsByMagneticCode(MagneticCode) Export
	
	Return FindLoyaltyCards(MagneticCode, Enums.CardCodeTypes.MagneticCode);
	
EndFunction

#EndRegion

#EndRegion 
