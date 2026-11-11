///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Specify the report form settings.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

	Settings.GenerateImmediately = True;
	Settings.Print.TopMargin = 5;
	Settings.Print.LeftMargin = 5;
	Settings.Print.BottomMargin = 5;
	Settings.Print.RightMargin = 5;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion
	
#Region EventHandlers

// Parameters:
//  ResultDocument - SpreadsheetDocument
//  DetailsData - DataCompositionDetailsData
//  StandardProcessing - Boolean
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ComposerSettings = SettingsComposer.GetSettings();

	InformationAboutCertificates = InformationAboutCertificates();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ComposerSettings, DetailsData);
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("Certificates", InformationAboutCertificates);
		
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

Function InformationAboutCertificates()

	QueryOptions = New Structure;
	
	CompositionSettings = SettingsComposer.GetSettings();
	
	ValidAfterParameter = CompositionSettings.DataParameters.Items.Find("ValidAfter");
	If ValidAfterParameter.Use And ValueIsFilled(ValidAfterParameter.Value) Then
		
		If TypeOf(ValidAfterParameter.Value) = Type("StandardBeginningDate") Then 
			QueryOptions.Insert("ValidAfter", ValidAfterParameter.Value.Date);
		Else
			QueryOptions.Insert("ValidAfter", ValidAfterParameter.Value);
		EndIf;
		
	Else
		QueryOptions.Insert("ValidAfter", Date(2000,1,1));
	EndIf;
	
	If Not Users.IsFullUser()
		And Not AccessRight("Update", Metadata.Catalogs.DigitalSignatureAndEncryptionApplications) Then
		UserSelect = Users.CurrentUser();
	Else
		UserSelect = Undefined;
	EndIf;
	
	UserParameter = CompositionSettings.DataParameters.Items.Find("User");
	If ValueIsFilled(UserSelect) Then
		UserParameter.Use = True;
		UserParameter.Value = UserSelect;
		QueryOptions.Insert("User", UserSelect);
	ElsIf UserParameter.Use Then
		QueryOptions.Insert("User", UserParameter.Value);
	Else
		QueryOptions.Insert("User", Undefined);
	EndIf;
	
	FindReissuedCertificates = Undefined;
	FindMRLOA = Undefined;
	NewCertificateField = New DataCompositionField("NewCertificate");
	MRLOAField = New DataCompositionField("MachineReadableLetterOfAuthority");
	For Each Item In CompositionSettings.Selection.Items Do
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Field = NewCertificateField Then
				FindReissuedCertificates = Item.Use;
			EndIf;
			If Item.Field = MRLOAField Then
				FindMRLOA = Item.Use;
			EndIf;
		EndIf;
	EndDo;
	
	For Each Item In CompositionSettings.Filter.Items Do
		If TypeOf(Item) = Type("DataCompositionFilterItem") Then
			If Item.LeftValue = NewCertificateField And FindReissuedCertificates = Undefined Then
				FindReissuedCertificates = Item.Use Or FindReissuedCertificates
					<> Undefined And FindReissuedCertificates;
			EndIf;
			If Item.LeftValue = MRLOAField Then
				FindMRLOA = Item.Use Or FindMRLOA <> Undefined And FindMRLOA;
			EndIf;
		EndIf;
	EndDo;
	
	If FindReissuedCertificates <> Undefined Then
		QueryOptions.Insert("FindReissuedCertificates", FindReissuedCertificates);
	Else
		QueryOptions.Insert("FindReissuedCertificates", False);
	EndIf;
	
	QueryOptions.Insert("FindMRLOA", False);
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If FindMRLOA <> Undefined And Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTS = Common.CommonModule("MachineReadableLettersOfAuthorityFTS");
		QueryOptions.Insert("FindMRLOA", FindMRLOA);
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority

	Query = New Query;
	
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref AS Certificate
	|INTO UserCertificates
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|WHERE
	|	&ConditionByUser1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Certificate,
	|	DigitalSignatureAndEncryptionKeysCertificates.CertificateData AS CertificateData,
	|	CASE
	|		WHEN DigitalSignatureAndEncryptionKeysCertificates.ValidBefore BETWEEN &CurrentDate AND &ExpiringOn
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ExpiringOn,
	|	CASE
	|		WHEN NOT UserCertificates.Certificate IS NULL
	|				OR DigitalSignatureAndEncryptionKeysCertificates.User <> VALUE(Catalog.Users.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Used,
	|	CASE
	|		WHEN DigitalSignatureAndEncryptionKeysCertificates.IssuedBy LIKE ""%Test_%""
	|				OR DigitalSignatureAndEncryptionKeysCertificates.IssuedBy LIKE ""%test%""
	|				OR DigitalSignatureAndEncryptionKeysCertificates.Description LIKE ""%_Test%""
	|				OR DigitalSignatureAndEncryptionKeysCertificates.Description LIKE ""%_Test%""
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Test_,
	|	DigitalSignatureAndEncryptionKeysCertificates.Firm AS Firm,
	|	DigitalSignatureAndEncryptionKeysCertificates.IssuedBy AS IssuedBy,
	|	DigitalSignatureAndEncryptionKeysCertificates.Organization AS Organization,
	|	DigitalSignatureAndEncryptionKeysCertificates.Individual AS Individual,
	|	DigitalSignatureAndEncryptionKeysCertificates.Revoked AS Revoked,
	|	DigitalSignatureAndEncryptionKeysCertificates.ValidBefore AS ValidBefore
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|		LEFT JOIN UserCertificates AS UserCertificates
	|		ON DigitalSignatureAndEncryptionKeysCertificates.Ref = UserCertificates.Certificate
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &ValidAfter
	|	AND &ConditionByUser2
	|	AND NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|
	|ORDER BY
	|	ValidBefore DESC";
	
	If ValueIsFilled(QueryOptions.User) Then
		Query.Text = StrReplace(Query.Text, "&ConditionByUser1", "ElectronicSignatureAndEncryptionKeyCertificatesUsers.User = &User");
		Query.Text = StrReplace(Query.Text, "&ConditionByUser2", "(DigitalSignatureAndEncryptionKeysCertificates.User = &User
	|			OR DigitalSignatureAndEncryptionKeysCertificates.Added = &User
	|			OR NOT UserCertificates.Certificate IS NULL)");
		Query.SetParameter("User", QueryOptions.User);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionByUser1", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ConditionByUser2", "TRUE");
	EndIf;
	
	Query.SetParameter("ValidAfter", QueryOptions.ValidAfter);
	Query.SetParameter("ExpiringOn", CurrentSessionDate() + 30*24*60*60);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	InformationAboutCertificates = Query.Execute().Unload();
	InformationAboutCertificates.Columns.Add("ThisIsQualifiedCertificate", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("Qualified", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("MRLOARequired", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("IsIndividualCertificateIssuanceRequired", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("Warning", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("TINENTITY", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("TIN", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("OGRN", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("IssuedTo", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("EndDate", New TypeDescription("Date"));
	InformationAboutCertificates.Columns.Add("IsPrivateKeyUsed", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("PrivateKeyExpirationDate", New TypeDescription("Date"));
	InformationAboutCertificates.Columns.Add("IndividualCertificate", New TypeDescription("Boolean"));
	InformationAboutCertificates.Columns.Add("NewCertificate", New TypeDescription("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates"));
	InformationAboutCertificates.Columns.Add("CompanySpecifiedInCertificateData", New TypeDescription("String"));
	InformationAboutCertificates.Columns.Add("MachineReadableLetterOfAuthority");
	
	For Each String In InformationAboutCertificates Do
		
		CertificateData = String.CertificateData.Get();
		If Not ValueIsFilled(CertificateData) Then
			String.Warning = NStr("vi = 'Chưa điền dữ liệu chứng thư trong danh mục';
									|ru = 'Не заполнены данные сертификата в справочнике';
									|en = 'Catalog requires certificate data'; fa = 'Catalog requires certificate data';
									|it = 'Не заполнены данные сертификата в справочнике';
									|pl = 'Catalog requires certificate data';
									|tr = 'Dizindeki sertifika verileri doldurulmamış'");
			Continue;
		EndIf;
		Try
			CryptoCertificate = New CryptoCertificate(CertificateData);
			CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
				CryptoCertificate, DigitalSignatureInternal.UTCOffset(), CertificateData);
		Except
			String.Warning = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đọc dữ liệu của chứng thư: %1';
					|ru = 'Не удалось прочитать данные сертификата: %1';
					|en = 'Cannot read the certificate properties: (%1)'; fa = 'Cannot read the certificate properties: (%1)';
					|it = 'Не удалось прочитать данные сертификата: %1';
					|pl = 'Cannot read the certificate properties: (%1)';
					|tr = 'Sertifika verileri okunamadı:%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		String.EndDate = CertificateProperties.EndDate;
		String.PrivateKeyExpirationDate = CertificateProperties.PrivateKeyExpirationDate;
		
		CertificateSubjectProperties = DigitalSignatureInternalClientServer.CertificateSubjectProperties(CryptoCertificate);
		If CertificateSubjectProperties.Property("TINENTITY") Then
			String.TINEntity = CertificateSubjectProperties.TINEntity;
		EndIf;
		If CertificateSubjectProperties.Property("TIN") Then
			String.TIN = CertificateSubjectProperties.TIN;
		EndIf;
		If CertificateSubjectProperties.Property("OGRN") Then
			String.OGRN = CertificateSubjectProperties.OGRN;
		ElsIf CertificateSubjectProperties.Property("OGRNIE") Then
			String.OGRN = CertificateSubjectProperties.OGRNIE;
		EndIf;
		String.CompanySpecifiedInCertificateData = CertificateSubjectProperties.Organization;
		String.IssuedTo = CertificateProperties.IssuedTo;
		
		If Not IsIssuerCertificate(String.OGRN) Then
			Result = DigitalSignatureInternal.ResultofCertificateAuthorityVerification(CryptoCertificate, CurrentSessionDate(), False, CertificateProperties);
			
			If ValueIsFilled(Result.Warning.ErrorText) Then
				String.Warning = Result.Warning.ErrorText;
			ElsIf ValueIsFilled(Result.Warning.AdditionalInfo) Then
				String.Warning = Result.Warning.AdditionalInfo;
			EndIf;
			
			String.Qualified = Not String.Test_ And Result.ThisIsQualifiedCertificate;
			String.IsIndividualCertificateIssuanceRequired = Result.ThisIsQualifiedCertificate 
				And Not Result.IsState And ValueIsFilled(String.Firm);
			
			String.IndividualCertificate = ValueIsFilled(String.TIN) And Not ValueIsFilled(String.TINEntity)
				And Not ValueIsFilled(String.OGRN);
			
			String.MRLOARequired = Result.ThisIsQualifiedCertificate And String.IndividualCertificate 
				And (Not Result.IsState Or IsTreasuryCertificate(CryptoCertificate));
			
			// StandardSubsystems.MachineReadableLettersOfAuthority
			If QueryOptions.FindMRLOA And Result.ThisIsQualifiedCertificate Then
					
				FilterForLettersOfAuthorityByCertificate = ModuleMachineReadableLettersOfAuthorityFTS.FilterForLettersOfAuthorityByCertificate(
					CryptoCertificate, "Representative");
				SelectedFields = New Array;
				SelectedFields.Add("MachineReadableLetterOfAuthority");
				LettersOfAuthority = ModuleMachineReadableLettersOfAuthorityFTS.LettersOfAuthorityWithFilter(FilterForLettersOfAuthorityByCertificate, 
					SelectedFields);
				
				If LettersOfAuthority.Count() > 0 Then
					String.MachineReadableLetterOfAuthority = LettersOfAuthority[0].MachineReadableLetterOfAuthority;
				EndIf;
			EndIf;
			// End StandardSubsystems.MachineReadableLettersOfAuthority
			
		EndIf;
		
	EndDo;
	
	If QueryOptions.FindReissuedCertificates Then
		
		InformationAboutCertificates.Indexes.Add("TIN, Qualified");
		
		For Each String In InformationAboutCertificates Do
			
			If Not ValueIsFilled(String.TIN) And Not ValueIsFilled(String.TINEntity) Then
				Continue;
			EndIf;
			
			Filter = New Structure;
			If ValueIsFilled(String.TIN) Then
				Filter.Insert("TIN", String.TIN);
			Else
				Filter.Insert("TINENTITY", String.TINEntity);
			EndIf;

			If String.Qualified Then
				Filter.Insert("Qualified", True);
			ElsIf String.Test_ Then
				Filter.Insert("Test_", True);
			Else
				Filter.Insert("ThisIsQualifiedCertificate", String.ThisIsQualifiedCertificate);
			EndIf;
			
			Filter.Insert("Revoked", False);

			Found4 = InformationAboutCertificates.FindRows(Filter);
			If Found4.Count() > 0 Then
				If Found4[0].ValidBefore > String.ValidBefore Then
					String.NewCertificate = Found4[0].Certificate;
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	Return InformationAboutCertificates;
	
EndFunction

Function IsIssuerCertificate(OGRN)
	
	If Not ValueIsFilled(OGRN) Then
		Return False;
	EndIf;
	If OGRN = "1047707030513" 
		Or OGRN = "1047797019830"
		Or OGRN = "1047702026701"
		Or OGRN = "1037700013020" Then
		Return True;
	EndIf;
	Return False;
	
EndFunction

Function IsTreasuryCertificate(CryptoCertificate)
	
	CertificateIssuerProperties = DigitalSignatureInternalClientServer.CertificateIssuerProperties(CryptoCertificate);

	If CertificateIssuerProperties.Property("OGRN") And CertificateIssuerProperties.OGRN = "1047797019830" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
	
#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Недопустимый вызов объекта на клиенте.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf