#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Query = New Query(
	"SELECT
	|	GiftCertificateKinds.CardType AS CardType
	|FROM
	|	Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|WHERE
	|	GiftCertificateKinds.Ref = &Ref");
	
	Query.SetParameter("Ref", Owner);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Selection.Next();
	
	If ValueIsFilled(Barcode) And (Selection.CardType = Enums.CardTypes.Barcode_ Or Selection.CardType = Enums.CardTypes.Mixed) Then
		
		GiftCertificates = GiftCertificatesServerCall.FindGiftCertificatesByBarcode(Barcode);
		For Each TSRow In GiftCertificates.RegisteredGiftCertificates Do
			If TSRow.Ref <> Ref And TSRow.GiftCertificateKind = Owner Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã vạch này đã được ghi nhận đối với phiếu quà tặng ""%1""';
																					|ru = 'Такой штрихкод уже зарегистрирован для подарочного сертификата ""%1""';
																					|en = 'This barcode is already registered for the ""%1"" gift card'; fa = 'This barcode is already registered for the ""%1"" gift card';
																					|it = 'Questo codice a barre è già registrato per il buono regalo ""%1""';
																					|pl = 'Taki kod kreskowy jest już zarejestrowany dla certyfikatu podarunkowego ""%1""';
																					|tr = 'Böyle bir barkod zaten bir hediye kuponu için kayıtlıdır ""%1""'"), TSRow.Ref),
					ThisObject,
					"Barcode",
					,
					Cancel);
			EndIf;
		EndDo;
		
		CertificateCorrespondsToRange = False;
		PossibleTypesOfCertificates = GiftCertificatesServer.GetPossibleTypesOfGiftCertificatesByGiftCertificateCode(Barcode, Enums.CardCodeTypes.Barcode);
		For Each PossibleTypeOfCertificate In PossibleTypesOfCertificates Do
			If PossibleTypeOfCertificate = Owner Then
				CertificateCorrespondsToRange = True;
				Break;
			EndIf;
		EndDo;
		If Not CertificateCorrespondsToRange Then
			Common.MessageToUser(
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
		
		GiftCertificates = GiftCertificatesServerCall.FindGiftCertificatesByMagneticCode(MagneticCode);
		For Each TSRow In GiftCertificates.RegisteredGiftCertificates Do
			If TSRow.Ref <> Ref And TSRow.GiftCertificateKind = Owner Then
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã từ này đã được ghi nhận đối với phiếu quà tặng ""%1""';
																					|ru = 'Такой магнитный код уже зарегистрирован для подарочного сертификата ""%1""';
																					|en = 'This magnetic code is already registered for the ""%1"" gift card'; fa = 'This magnetic code is already registered for the ""%1"" gift card';
																					|it = 'Questo codice magnetico è già registrato per il buono regalo ""%1""';
																					|pl = 'Taki kod magnetyczny jest już zarejestrowany dla certyfikatu podarunkowego ""%1""';
																					|tr = 'Böyle bir manyetik kod zaten bir hediye kuponu için kayıtlıdır ""%1""'"), TSRow.Ref),
					ThisObject,
					"MagneticCode",
					,
					Cancel);
			EndIf;
		EndDo;
		
		CertificateCorrespondsToRange = False;
		PossibleTypesOfCertificates = GiftCertificatesServer.GetPossibleTypesOfGiftCertificatesByGiftCertificateCode(MagneticCode, Enums.CardCodeTypes.MagneticCode);
		For Each PossibleTypeOfCertificate In PossibleTypesOfCertificates Do
			If PossibleTypeOfCertificate = Owner Then
				CertificateCorrespondsToRange = True;
				Break;
			EndIf;
		EndDo;
		If Not CertificateCorrespondsToRange Then
			Common.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Mã từ không nằm trong dãi mã vạch hợp lệ ""%1""';
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
	
	NotCheckedAttributeArray = New Array;
	If Selection.CardType = Enums.CardTypes.Magnetic Then
		NotCheckedAttributeArray.Add("Barcode");
	EndIf;
	
	If Selection.CardType = Enums.CardTypes.Barcode_ Then
		NotCheckedAttributeArray.Add("MagneticCode");
	EndIf;
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	GiftCardAccounting25 = GiftCardAccounting25();
	
	If GiftCardAccounting25 Then
		If Not ValueIsFilled(Counterparty) Then
			Counterparty = Catalogs.Counterparties.RetailCustomer;
		EndIf;
		If Not ValueIsFilled(Partner) Then
			Partner = Catalogs.Partners.RetailCustomer;
		EndIf;
		OrganizationOfGiftCertificateType = Common.ObjectAttributeValue(Owner,"Organization");
		VATTaxation = VATAccountingERP.AccountingParametersForOrganization(
			OrganizationOfGiftCertificateType,
			CurrentSessionDate(),
			Undefined, Department).TaxationOfRetailVAT;
	EndIf;

	CreatePaymentObjectForGiftCertificate2_5(GiftCardAccounting25, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure CreatePaymentObjectForGiftCertificate2_5(GiftCardAccounting25, Cancel)
	
	Query = New Query(
	"SELECT
	|	GiftCertificateKinds.CardType AS CardType
	|FROM
	|	Catalog.GiftCertificateKinds AS GiftCertificateKinds
	|WHERE
	|	GiftCertificateKinds.Ref = &Ref");
	Query.SetParameter("Ref", Owner);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Selection.CardType = Enums.CardTypes.Magnetic Then
		Barcode = "";
	EndIf;
	
	If Selection.CardType = Enums.CardTypes.Barcode_ Then
		MagneticCode = "";
	EndIf;
	
	If GiftCardAccounting25 Then
		ARAPAccountingServer.BeforeWrite(ThisObject, Cancel);
	EndIf;
	
EndProcedure

Function GiftCardAccounting25()
	
	Return Catalogs.GiftCertificates.GiftCardAccounting25(ThisObject);
	
EndFunction

#EndRegion

#EndIf
