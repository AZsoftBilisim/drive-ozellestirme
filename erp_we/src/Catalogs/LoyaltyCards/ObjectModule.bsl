#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	Query = New Query(
	"SELECT
	|	LoyaltyCardKinds.CardType AS CardType,
	|	LoyaltyCardKinds.Personalized AS Personalized
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|WHERE
	|	LoyaltyCardKinds.Ref = &Ref");
	
	Query.SetParameter("Ref", Owner);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
	
		If ValueIsFilled(Barcode) And (Selection.CardType = Enums.CardTypes.Barcode_ Or Selection.CardType = Enums.CardTypes.Mixed) Then
			
			LoyaltyCards = LoyaltyCardServerCall.FindLoyaltyCardsByBarcode(Barcode);
			For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
				If TSRow.Ref <> Ref And TSRow.CardKind = Owner Then
					CommonClientServer.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã vạch này đã được ghi nhận cho thẻ khách hàng thân thiết ""%1""';
																						|ru = 'Такой штрихкод уже зарегистрирован для карты лояльности ""%1""';
																						|en = 'This barcode has already been registered for loyalty card ""%1""'; fa = 'This barcode has already been registered for loyalty card ""%1""';
																						|it = 'Questo codice a barre è già registrato per la carta fedeltà ""%1""';
																						|pl = 'Taki kod kreskowy jest już zarejestrowany dla karty lojalnościowej ""%1""';
																						|tr = 'Bu barkod, ""%1"" sadakat kartı için zaten kayıtlı'"), TSRow.Ref),
						ThisObject,
						"Barcode",
						,
						Cancel);
				EndIf;
			EndDo;
			
			MapCorrespondsToRange = False;
			PossibleTypesOfMaps = LoyaltyCardsServer.GetPossibleTypesOfLoyaltyCardsByCardCode(Barcode, Enums.CardCodeTypes.Barcode);
			For Each PossibleMapView In PossibleTypesOfMaps Do
				If PossibleMapView = Owner Then
					MapCorrespondsToRange = True;
					Break;
				EndIf;
			EndDo;
			If Not MapCorrespondsToRange Then
				CommonClientServer.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã vạch không nằm trong dải mã vạch hợp lệ ""%1""';
																					|ru = 'Штрихкод не входит в допустимый диапазон штрихкодов ""%1""';
																					|en = 'Barcode is not included in the allowable barcode range ""%1""'; fa = 'Barcode is not included in the allowable barcode range ""%1""';
																					|it = 'Il codice a barre non fa parte dell''intervallo ammissibile per i codici a barre ""%1""';
																					|pl = 'Kod kreskowy nie wchodzi w dostępny zakres kodów kreskowych ""%1""';
																					|tr = 'Barkod izin verilen barkod aralığı içinde değil ""%1""'"), Owner),
					ThisObject,
					"Barcode",
					,
					Cancel);
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(MagneticCode) And (Selection.CardType = Enums.CardTypes.Magnetic Or Selection.CardType = Enums.CardTypes.Mixed) Then
			
			LoyaltyCards = LoyaltyCardsServer.FindLoyaltyCardsByMagneticCode(MagneticCode);
			For Each TSRow In LoyaltyCards.RegisteredLoyaltyCards Do
				If TSRow.Ref <> Ref And TSRow.CardKind = Owner Then
					CommonClientServer.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã từ này đã được ghi nhận cho thẻ khách hàng thân thiết ""%1""';
																						|ru = 'Такой магнитный код уже зарегистрирован для карты лояльности ""%1""';
																						|en = 'This magnetic code has already been registered for loyalty card ""%1""'; fa = 'This magnetic code has already been registered for loyalty card ""%1""';
																						|it = 'Questo codice magnetico è già registrato per la carta fedeltà ""%1""';
																						|pl = 'Taki kod magnetyczny jest już zarejestrowany dla karty lojalnościowej ""%1""';
																						|tr = 'Bu manyetik kodu, ""%1"" sadakat kartı için zaten kayıtlı'"), TSRow.Ref),
						ThisObject,
						"MagneticCode",
						,
						Cancel);
				EndIf;
			EndDo;
			
			MapCorrespondsToRange = False;
			PossibleTypesOfMaps = LoyaltyCardsServer.GetPossibleTypesOfLoyaltyCardsByCardCode(MagneticCode, Enums.CardCodeTypes.MagneticCode);
			For Each PossibleMapView In PossibleTypesOfMaps Do
				If PossibleMapView = Owner Then
					MapCorrespondsToRange = True;
					Break;
				EndIf;
			EndDo;
			If Not MapCorrespondsToRange Then
				CommonClientServer.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã từ không nằm trong dải mã vạch hợp lệ ""%1""';
																					|ru = 'Магнитный код не входит в допустимый диапазон штрихкодов ""%1""';
																					|en = 'Magnetic code is not included in the allowable barcode range ""%1""'; fa = 'Magnetic code is not included in the allowable barcode range ""%1""';
																					|it = 'Il codice magnetico non fa parte dell''intervallo ammissibile per i codici a barre ""%1""';
																					|pl = 'Kod magnetyczny nie wchodzi w dostępny zakres kodów kreskowych ""%1""';
																					|tr = 'Manyetik kod izin verilen barkod aralığı içinde değil ""%1""'"), Owner),
					ThisObject,
					"MagneticCode",
					,
					Cancel);
			EndIf;
			
		EndIf;
		
		If Selection.CardType = Enums.CardTypes.Magnetic Then
			NotCheckedAttributeArray.Add("Barcode");
		EndIf;
		If Selection.CardType = Enums.CardTypes.Barcode_ Then
			NotCheckedAttributeArray.Add("MagneticCode");
		EndIf;
		If Not Selection.Personalized Then
			NotCheckedAttributeArray.Add("Partner");
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Query = New Query(
	"SELECT
	|	LoyaltyCardKinds.CardType AS CardType,
	|	LoyaltyCardKinds.Personalized AS Personalized
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|WHERE
	|	LoyaltyCardKinds.Ref = &Ref");
	Query.SetParameter("Ref", Owner);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.CardType = Enums.CardTypes.Magnetic Then
		Barcode = "";
	EndIf;
	
	If Selection.CardType = Enums.CardTypes.Barcode_ Then
		MagneticCode = "";
	EndIf;
	
	If Not Selection.Personalized Then
		Partner    = Undefined;
		Counterparty = Undefined;
		Terms = Undefined;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Description = "";
	
EndProcedure

#EndRegion

#EndIf
