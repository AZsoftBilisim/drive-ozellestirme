///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// For internal use only.
// 
// Returns:
//  FixedStructure:
//   * UseDigitalSignature - Boolean
//   * UseEncryption - Boolean
//   * VerifyDigitalSignaturesOnTheServer - Boolean
//   * GenerateDigitalSignaturesAtServer - Boolean
//   * CertificateIssueRequestAvailable - Boolean
//   * ApplicationsDetailsCollection - FixedArray of See ApplicationDetails
//   * DescriptionsOfTheProgramsOnTheLink - FixedMap of KeyAndValue:
//       ** Key - CatalogRef.DigitalSignatureAndEncryptionApplications
//       ** Value - See ApplicationDetails
//
Function CommonSettings() Export
	
	CommonSettings = New Structure;
	
	SetPrivilegedMode(True);
	
	CommonSettings.Insert("AccessToInternetServicesAllowed",
		Constants.AllowAccessToDigitalSignatureInternetServices.Get()
			And Common.AccessToInternetServicesAllowed());
	
	CommonSettings.Insert("UseDigitalSignature",
		Constants.UseDigitalSignature.Get());
	
	CommonSettings.Insert("UseEncryption",
		Constants.UseEncryption.Get());
	
	If Common.DataSeparationEnabled()
	 Or Common.FileInfobase()
	   And Not Common.ClientConnectedOverWebServer() Then
		
		CommonSettings.Insert("VerifyDigitalSignaturesOnTheServer", False);
		CommonSettings.Insert("GenerateDigitalSignaturesAtServer", False);
	Else
		CommonSettings.Insert("VerifyDigitalSignaturesOnTheServer",
			Constants.VerifyDigitalSignaturesOnTheServer.Get());
		
		CommonSettings.Insert("GenerateDigitalSignaturesAtServer",
			Constants.GenerateDigitalSignaturesAtServer.Get());
	EndIf;
	CommonSettings.Insert("UseMobileSignatureService",
			DigitalSignature.UseMobileSignatureService());
	
	CommonSettings.Insert("CertificateIssueRequestAvailable", 
		Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined);
		
	If CommonSettings.CertificateIssueRequestAvailable Then
		ModuleApplicationForIssuingANewQualifiedCertificate = Common.CommonModule("DataProcessors.ApplicationForNewQualifiedCertificateIssue");
		CommonSettings.CertificateIssueRequestAvailable = ModuleApplicationForIssuingANewQualifiedCertificate.CertificateIssueRequestAvailable();
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Programs.Ref AS Ref,
	|	Programs.Description AS Presentation,
	|	Programs.ApplicationName AS ApplicationName,
	|	Programs.ApplicationType AS ApplicationType,
	|	Programs.SignAlgorithm AS SignAlgorithm,
	|	Programs.HashAlgorithm AS HashAlgorithm,
	|	Programs.EncryptAlgorithm AS EncryptAlgorithm,
	|	Programs.UsageMode AS UsageMode
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs
	|WHERE
	|	NOT Programs.DeletionMark
	|	AND NOT Programs.IsBuiltInCryptoProvider
	|
	|ORDER BY
	|	Description";
	
	Selection = Query.Execute().Select();
	ApplicationsDetailsCollection = New Array;
	DescriptionsOfTheProgramsOnTheLink = New Map;
	
	ApplicationsByNamesWithType = New Map;
	ApplicationsByPublicKeyAlgorithmsIDs = New Map;
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	SetsOfAlgorithmsForCreatingASignature = DigitalSignatureInternalClientServer.SetsOfAlgorithmsForCreatingASignature();
	
	For Each SettingToSupply In SettingsToSupply Do
		
		ApplicationSearchKeyByNameWithType = DigitalSignatureInternalClientServer.ApplicationSearchKeyByNameWithType(
			SettingToSupply.ApplicationName, SettingToSupply.ApplicationType);
			
		LongDesc = ApplicationDetails();
		FillPropertyValues(LongDesc, SettingToSupply);
		LongDesc.SignatureVerificationAlgorithms = SignatureVerificationAlgorithms(SettingToSupply);
		FixedDescription = New FixedStructure(LongDesc);
		
		ApplicationsByNamesWithType.Insert(ApplicationSearchKeyByNameWithType, FixedDescription);
		
		PublicKeyID = Undefined;
		For Each CurrentItem In SetsOfAlgorithmsForCreatingASignature Do
			If CurrentItem.SignatureAlgorithmNames.Find(SettingToSupply.SignAlgorithm) <> Undefined Then
				PublicKeyID = CurrentItem.IDOfThePublicKeyAlgorithm;
				Break;
			EndIf;
		EndDo;
		
		If PublicKeyID <> Undefined Then
			AppsByPublicKey = ApplicationsByPublicKeyAlgorithmsIDs.Get(PublicKeyID);
			If AppsByPublicKey = Undefined Then
				AppsByPublicKey = New Map; 
			EndIf;
			AppsByPublicKey.Insert(ApplicationSearchKeyByNameWithType, SettingToSupply.Id);
			ApplicationsByPublicKeyAlgorithmsIDs.Insert(PublicKeyID, AppsByPublicKey);
		EndIf;
		
	EndDo;
	
	While Selection.Next() Do
		Filter = New Structure("ApplicationName, ApplicationType", Selection.ApplicationName, Selection.ApplicationType);
		Rows = SettingsToSupply.FindRows(Filter);
		If Rows.Count() = 0 Then
			Id = "";
			SignatureVerificationAlgorithms = New Array;
		Else
			String = Rows[0]; // ValueTableRow of See DigitalSignatureInternal.ApplicationsSettingsToSupply
			Id = String.Id;
			SignatureVerificationAlgorithms = SignatureVerificationAlgorithms(String);
		EndIf;
		
		LongDesc = ApplicationDetails();
		FillPropertyValues(LongDesc, Selection);
		LongDesc.Id = Id;
		LongDesc.SignatureVerificationAlgorithms = SignatureVerificationAlgorithms;
		
		FixedDescription = New FixedStructure(LongDesc);
		ApplicationsDetailsCollection.Add(FixedDescription);
		
		If Selection.UsageMode <> Enums.DigitalSignatureAppUsageModes.Automatically Then
			ApplicationSearchKeyByNameWithType = DigitalSignatureInternalClientServer.ApplicationSearchKeyByNameWithType(
				Selection.ApplicationName, Selection.ApplicationType);
			// Replace the 1C-supplied setting with the setting from the catalog.
			ApplicationsByNamesWithType.Insert(ApplicationSearchKeyByNameWithType, FixedDescription);
		EndIf;
		
		DescriptionsOfTheProgramsOnTheLink.Insert(LongDesc.Ref, FixedDescription);
	EndDo;
	
	CommonSettings.Insert("ApplicationsDetailsCollection", New FixedArray(ApplicationsDetailsCollection));
	CommonSettings.Insert("DescriptionsOfTheProgramsOnTheLink", New FixedMap(DescriptionsOfTheProgramsOnTheLink));
	CommonSettings.Insert("SupplyThePathToTheProgramModules",
		Catalogs.DigitalSignatureAndEncryptionApplications.SupplyThePathToTheProgramModules());
	
	CommonSettings.Insert("SettingsVersion", String(New UUID));
	CommonSettings.Insert("AvailableAdvancedSignature", True);
	
	TimestampServersAddresses = Constants.TimestampServersAddresses.Get();
	If Not IsBlankString(TimestampServersAddresses) Then
		CommonSettings.Insert("TimestampServersAddresses", DigitalSignatureInternal.TimestampServersAddresses(TimestampServersAddresses));
	Else
		CommonSettings.Insert("TimestampServersAddresses", New Array);
	EndIf;
	
	CommonSettings.Insert("ThisistheServiceModelwithEnhancementAvailable",
		ThisistheServiceModelwithEnhancementAvailable());
		
	AvailableCheckAccordingtoCAList = False;
	DigitalSignatureLocalization.OnDetermineAvailabilityOfCheckByCAList(AvailableCheckAccordingtoCAList);
	CommonSettings.Insert("AvailableCheckAccordingtoCAList", AvailableCheckAccordingtoCAList);

	CommonSettings.Insert("YouCanCheckTheCertificateInTheCloudServiceWithTheFollowingParameters", 
		YouCanCheckTheCertificateInTheCloudServiceWithTheFollowingParameters());
	
	CommonSettings.Insert("ApplicationsByNamesWithType", New FixedMap(ApplicationsByNamesWithType));
	CommonSettings.Insert("ApplicationsByPublicKeyAlgorithmsIDs",
		New FixedMap(ApplicationsByPublicKeyAlgorithmsIDs));
	
	IndividualUsed = Not (Metadata.DefinedTypes.Individual.Type.Types().Count() = 1
		And Metadata.DefinedTypes.Individual.Type.Types()[0] = Type("String"));
		
	IsCompanyUsed = Not (Metadata.DefinedTypes.Organization.Type.Types().Count() = 1
		And Metadata.DefinedTypes.Organization.Type.Types()[0] = Type("String"));
	CommonSettings.Insert("IsCompanyUsed", IsCompanyUsed);
	
	OverriddenSettings = New Structure("IndividualUsed", IndividualUsed);
	DigitalSignatureOverridable.OnDefineSettings(OverriddenSettings);
	CommonSettings.Insert("IndividualUsed", OverriddenSettings.IndividualUsed);
		
	Return New FixedStructure(CommonSettings);
	
EndFunction

// Returns:
//  Structure:
//   * Ref - CatalogRef.DigitalSignatureAndEncryptionApplications
//   * Presentation - String
//   * ApplicationName - String
//   * ApplicationType - Number
//   * SignAlgorithm - String
//   * HashAlgorithm - String
//   * EncryptAlgorithm - String
//   * Id - String
//
Function ApplicationDetails() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Ref");
	LongDesc.Insert("Presentation");
	LongDesc.Insert("ApplicationName");
	LongDesc.Insert("ApplicationType");
	LongDesc.Insert("SignAlgorithm");
	LongDesc.Insert("HashAlgorithm");
	LongDesc.Insert("EncryptAlgorithm");
	LongDesc.Insert("Id");
	LongDesc.Insert("SignatureVerificationAlgorithms");
	LongDesc.Insert("UsageMode");

	Return LongDesc;
	
EndFunction

Function OwnersTypes(RefsOnly = False) Export
	
	Result = New Map;
	Types = Metadata.DefinedTypes.SignedObject.Type.Types();
	
	TypesToExclude = New Map;
	TypesToExclude.Insert(Type("Undefined"), True);
	TypesToExclude.Insert(Type("String"), True);
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		TypesToExclude.Insert(ModuleFilesOperationsInternal.FilesVersionsCatalog(), True);
	EndIf;
	
	For Each Type In Types Do
		If TypesToExclude.Get(Type) <> Undefined Then
			Continue;
		EndIf;
		Result.Insert(Type, True);
		If Not RefsOnly Then
			ObjectTypeName = StrReplace(Metadata.FindByType(Type).FullName(), ".", "Object.");
			Result.Insert(Type(ObjectTypeName), True);
		EndIf;
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

Function CryptoErrorsClassifier() Export
	
	Return DigitalSignatureInternal.CryptoErrorsClassifier();
	
EndFunction

Function ClassifierError(TextToSearchInClassifier, ErrorAtServer, SignatureVerificationError, IsCertificateSpecified) Export
	
	If Not ValueIsFilled(TextToSearchInClassifier) Then
		Return Undefined;
	EndIf;
	
	ErrorsClassifier = DigitalSignatureInternalCached.CryptoErrorsClassifier();
	
	If Not ValueIsFilled(ErrorsClassifier) Then
		Return Undefined;
	EndIf;
	
	SearchText = Lower(TextToSearchInClassifier);
	
	If SignatureVerificationError Then
		If ErrorAtServer Then
			Filter = New Structure("OnlyClient, IsSignatureVerificationError", False, True);
		Else
			Filter = New Structure("OnlyServer, IsSignatureVerificationError", False, True);
		EndIf;

		ErrorString = FindErrorString(ErrorsClassifier, Filter, SearchText, ErrorAtServer, TextToSearchInClassifier, IsCertificateSpecified);
		If ErrorString <> Undefined Then
			Return ErrorString;
		EndIf;
	EndIf;

	If ErrorAtServer Then
		Filter = New Structure("OnlyClient", False);
	Else
		Filter = New Structure("OnlyServer", False);
	EndIf;

	Return FindErrorString(ErrorsClassifier, Filter, SearchText, ErrorAtServer, TextToSearchInClassifier, IsCertificateSpecified);

EndFunction

Function FindErrorString(ErrorsClassifier, Filter, SearchText, ErrorAtServer, ErrorText, IsCertificateSpecified)
	
	Rows = ErrorsClassifier.FindRows(Filter);
	For Each ClassifierRow In Rows Do

		If StrFind(SearchText, ClassifierRow.ErrorTextLowerCase) <> 0 Then

			ErrorPresentation = DigitalSignatureInternal.ErrorPresentation();
			FillPropertyValues(ErrorPresentation, ClassifierRow);
			ErrorPresentation.RemedyActions = ActionsToFixErrorsRead(
				ErrorPresentation.Remedy);
				
			If ValueIsFilled(ErrorPresentation.RemedyActions)
				And ErrorPresentation.RemedyActions.Find("ApplyforCertificate") <> Undefined Then
				Decision = StrSplit(ErrorPresentation.Decision, Chars.LF);
				CurrentIndex = Decision.UBound();
				While CurrentIndex >= 0 Do
					If StrFind(Decision[CurrentIndex], "ApplyforCertificate") > 0 Then
						Decision.Delete(CurrentIndex);
					EndIf;
					CurrentIndex = CurrentIndex - 1;
				EndDo;
				ErrorPresentation.Decision = StrConcat(Decision, Chars.LF);
			EndIf;
			
			SupplementSolutionWithAutomaticActions(ErrorPresentation.Decision,
				ErrorPresentation.RemedyActions, ErrorAtServer, ErrorText, IsCertificateSpecified);
			Add_Parameters(ErrorPresentation.Cause, ErrorPresentation.Decision,
				ErrorPresentation.RemedyActions, ErrorText);
			
			ErrorPresentation.Cause = StringFunctions.FormattedString(ErrorPresentation.Cause);
			ErrorPresentation.Decision = StringFunctions.FormattedString(ErrorPresentation.Decision);

			Return New FixedStructure(ErrorPresentation);

		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure SupplementSolutionWithAutomaticActions(Decision, RemedyActions, ErrorAtServer, ErrorText, IsCertificateSpecified)
	
	If Not ValueIsFilled(RemedyActions) Then
		Return;
	EndIf;
	
	HasGetFilesFromInternet = Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet");
	
	For Each Action In RemedyActions Do
		
		If Action = "SetListOfCertificateRevocation" And Not ErrorAtServer And HasGetFilesFromInternet And IsCertificateSpecified Then
			Decision = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '- <a href=%1>Hãy thiết lập danh sách thu hồi</a> của trung tâm chứng thực tự động.
				|%2';
				|ru = '• <a href=%1>Установите список отзыва</a> удостоверяющего центра автоматически.
				|%2';
				|en = '• <a href=%1>Install a revocation list</a> of a certificate authority automatically.
				|%2'; fa = '• <a href=%1>Install a revocation list</a> of a certificate authority automatically.
				|%2';
				|it = '• <a href=%1>Установите список отзыва</a> удостоверяющего центра автоматически.
				|%2';
				|pl = '• <a href=%1>Install a revocation list</a> of a certificate authority automatically.
				|%2';
				|tr = '</a>Geri bildirim listesi <a href=%1> kurun otomatik belgelendirme kutusu.
				|%2'"), Action, Decision);
		ElsIf Action = "InstallRootCertificate" And Not ErrorAtServer And IsCertificateSpecified Then
			Decision = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '- <a href=%1>Hãy thiết lập chứng thư gốc</a> của trung tâm chứng thực tự động.
				|%2';
				|ru = '• <a href=%1>Установите корневой сертификат</a> удостоверяющего центра автоматически.
				|%2';
				|en = '- <a href=%1>Install a root certificate</a> of a certificate authority automatically.
				|%2'; fa = '- <a href=%1>Install a root certificate</a> of a certificate authority automatically.
				|%2';
				|it = '• <a href=%1>Установите корневой сертификат</a> удостоверяющего центра автоматически.
				|%2';
				|pl = '- <a href=%1>Install a root certificate</a> of a certificate authority automatically.
				|%2';
				|tr = '-</a>Kök sertifikasını <a href=%1> kurun otomatik belgelendirme kutusu.
				|%2'"), Action, Decision);
		ElsIf Action = "InstallCertificate" And Not ErrorAtServer And IsCertificateSpecified Then
			Decision = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '• <a href=%1>Tự động thiết lập chứng thư</a> trong Kho chứa chứng thư cá nhân của người sử dụng hệ điều hành.
				|%2';
				|ru = '• <a href=%1>Установите сертификат</a> в Личное хранилище сертификатов пользователя операционной системы автоматически.
				|%2';
				|en = '- <a href=%1>Install the certificate</a> in the Current user/Personal certificate store automatically.
				|%2'; fa = '- <a href=%1>Install the certificate</a> in the Current user/Personal certificate store automatically.
				|%2';
				|it = '• <a href=%1>Установите сертификат</a> в Личное хранилище сертификатов пользователя операционной системы автоматически.
				|%2';
				|pl = '- <a href=%1>Install the certificate</a> in the Current user/Personal certificate store automatically.
				|%2';
				|tr = '<a href=%1>Sertifikayı işletim sistemi kullanıcısının Kişisel Sertifika Deposuna otomatik olarak yükleyin</a>.
				|%2'"), Action, Decision);
		ElsIf Action = "InstallCertificateIntoContainer" And Not ErrorAtServer And IsCertificateSpecified Then
			Decision = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '- <a href=%1>Hãy thiết lập chứng thư trong nơi chứa dữ liệu</a> trực tiếp từ ứng dụng.
				|%2';
				|ru = '• <a href=%1>Установите сертификат в контейнер</a> прямо из приложения.
				|%2';
				|en = '• <a href=%1>Install certificate on container</a> from the app.
				|%2'; fa = '• <a href=%1>Install certificate on container</a> from the app.
				|%2';
				|it = '• <a href=%1>Установите сертификат в контейнер</a> прямо из приложения.
				|%2';
				|pl = '• <a href=%1>Install certificate on container</a> from the app.
				|%2';
				|tr = '• <a href=%1>Sertifikayı doğrudan uygulamadan konteynere</a> yükleyin.
				|%2'"), Action, Decision);
				
		ElsIf Action = "ApplyforCertificate" And IsCertificateSpecified Then
			
			Decision = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '• <a href=%1>Hãy nộp yêu cầu</a> đối với chứng thư mới.
				|%2';
				|ru = '• <a href=%1>Подайте заявление</a> на новый сертификат.
				|%2';
				|en = '• Submit a <a href=%1>certificate issuance application</a>.
				|%2'; fa = '• Submit a <a href=%1>certificate issuance application</a>.
				|%2';
				|it = '• Submit a <a href=%1>certificate issuance application</a>.
				|%2';
				|pl = '• Submit a <a href=%1>certificate issuance application</a>.
				|%2';
				|tr = '• <a href=%1>Yeni bir sertifika için</a> başvuru yapın.
				|%2'"), Action, Decision);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure Add_Parameters(Cause, Decision, RemedyActions, ErrorText)
	
	If Not ValueIsFilled(RemedyActions) Then
		Return;
	EndIf;
	
	For Each Action In RemedyActions Do
		
		If Action = "SpecifyLinkToServiceInReason" Then
			AddLinkToService(Cause, ErrorText);
		ElsIf Action = "SpecifyLinkToServiceInSolution" Then
			AddLinkToService(Decision, ErrorText);
		EndIf;
		
	EndDo;
	
	RemoveParametersFromString(Cause);
	RemoveParametersFromString(Decision);
	
EndProcedure

Procedure AddLinkToService(String, ErrorText)

	Template = "(?i)\b(https?|ftps?|file)://[-A-Z0-9+&@#/%?=~_|$!:,.;]*[A-Z0-9+&@#/%?=_|$]";
	SearchResult = StrFindByRegularExpression(ErrorText, Template);
	If SearchResult.StartIndex <> 0 Then
		Address = SearchResult.Value;
		If StrStartsWith(Address, "http") Then
			Address = StrTemplate("<a href=%1>%1</a>", Address);
		EndIf;
		String = StringFunctionsClientServer.SubstituteParametersToString(String,
			Address);
	EndIf;

EndProcedure

Procedure RemoveParametersFromString(String)
	
	Template = "\b(:? ?)%[0-3]";
	SearchResult = StrFindByRegularExpression(String, Template);
	While SearchResult.StartIndex <> 0 Do
		String = StrReplace(String, SearchResult.Value, "");
		SearchResult = StrFindByRegularExpression(String, Template);
	EndDo;
	
EndProcedure

// For internal use only.
Function ActionsToFixErrorsRead(Val Remedy)
	
	If Not ValueIsFilled(Remedy) Then
		Return Undefined;
	EndIf;
	
	Remedy = Common.JSONValue(Remedy, , False); // Structure
	Return Remedy.EliminationMethods;
	
EndFunction

Function ApplicationsPathsAtLinuxServers(ComputerName) Export
	
	Query = New Query;
	Query.SetParameter("ComputerName", ComputerName);
	Query.Text =
	"SELECT
	|	ApplicationPaths.Application,
	|	ApplicationPaths.ApplicationPath
	|FROM
	|	InformationRegister.PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers AS ApplicationPaths
	|WHERE
	|	ApplicationPaths.ComputerName = &ComputerName";
	
	ApplicationsPathsAtLinuxServers = New Map;
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		ErrorsTexts = New Array;
		DescriptionOfWay = New Structure;
		DescriptionOfWay.Insert("ApplicationPath", Selection.ApplicationPath);
		DescriptionOfWay.Insert("Exists", OneOfTheModulesExists(Selection.ApplicationPath, ErrorsTexts));
		DescriptionOfWay.Insert("ErrorText", ?(DescriptionOfWay.Exists, "",
			StrConcat(ErrorsTexts, Chars.LF)));
		ApplicationsPathsAtLinuxServers.Insert(Selection.Application, DescriptionOfWay);
	EndDo;
	
	CommonSettings = DigitalSignature.CommonSettings();
	NameOfThePlatformType = CommonClientServer.NameOfThePlatformType();
	
	For Each ApplicationDetails In CommonSettings.ApplicationsDetailsCollection Do
		If ApplicationsPathsAtLinuxServers.Get(ApplicationDetails.Ref) <> Undefined Then
			If ValueIsFilled(ApplicationDetails.Id) Then
				ApplicationsPathsAtLinuxServers.Insert(ApplicationDetails.Id,
					ApplicationsPathsAtLinuxServers.Get(ApplicationDetails.Ref));
			EndIf;
			Continue;
		EndIf;
		DescriptionOfWay = DescriptionOfThePathByProgramID(ApplicationDetails.Id,
			CommonSettings.SupplyThePathToTheProgramModules, NameOfThePlatformType);
		If DescriptionOfWay <> Undefined Then
			ApplicationsPathsAtLinuxServers.Insert(ApplicationDetails.Ref, DescriptionOfWay);
			ApplicationsPathsAtLinuxServers.Insert(ApplicationDetails.Id, DescriptionOfWay);
		EndIf;
	EndDo;
	
	SettingsToSupply = Catalogs.DigitalSignatureAndEncryptionApplications.ApplicationsSettingsToSupply();
	For Each SettingToSupply In SettingsToSupply Do
		If ApplicationsPathsAtLinuxServers.Get(SettingToSupply.Id) <> Undefined Then
			Continue;
		EndIf;
		DescriptionOfWay = DescriptionOfThePathByProgramID(SettingToSupply.Id,
			CommonSettings.SupplyThePathToTheProgramModules, NameOfThePlatformType);
		If DescriptionOfWay <> Undefined Then
			ApplicationsPathsAtLinuxServers.Insert(SettingToSupply.Id, DescriptionOfWay);
		EndIf;
	EndDo;
	
	Return New FixedMap(ApplicationsPathsAtLinuxServers);
	
EndFunction

Function DescriptionOfThePathByProgramID(Id,
			SupplyThePathToTheProgramModules, PlatformTypeByString)
	
	DescriptionOfWay = Undefined;
	
	For Each ThePathToTheProgramModules In SupplyThePathToTheProgramModules Do
		If Not StrStartsWith(Id, ThePathToTheProgramModules.Key) Then
			Continue;
		EndIf;
		PathsToProgramModules = ThePathToTheProgramModules.Value.Get(PlatformTypeByString);
		If PathsToProgramModules = Undefined Then
			Continue;
		EndIf;
		ErrorsTexts = New Array;
		DescriptionOfWay = New Structure("ApplicationPath, Exists, ErrorText",
			PathsToProgramModules[0], False, "");
		For Each ThePathToTheModules In PathsToProgramModules Do
			If Not OneOfTheModulesExists(ThePathToTheModules, ErrorsTexts) Then
				Continue;
			EndIf;
			DescriptionOfWay.ApplicationPath = ThePathToTheModules;
			DescriptionOfWay.Exists = True;
			Break;
		EndDo;
		If Not DescriptionOfWay.Exists Then
			DescriptionOfWay.ErrorText = StrConcat(ErrorsTexts, Chars.LF);
		EndIf;
		Break;
	EndDo;
	
	Return DescriptionOfWay;
	
EndFunction

Function OneOfTheModulesExists(ThePathToTheModules, ErrorsTexts)
	
	ModulesPrograms = StrSplit(ThePathToTheModules, ":");
	Result = False;
	For Each ModuleOfProgram In ModulesPrograms Do
		File = New File(ModuleOfProgram);
		Try
			Exists = File.Exists();
		Except
			Exists = False;
			ErrorInfo = ErrorInfo();
			ErrorsTexts.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
		If Exists Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function YouCanCheckTheCertificateInTheCloudServiceWithTheFollowingParameters()
	
	If Not DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
		Return False;
	EndIf;
	
	ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
	Version = ModuleSaaSTechnology.LibraryVersion();
	
	Return CommonClientServer.CompareVersions(Version, "2.0.3.0") > 0;
	
EndFunction

Function ThisistheServiceModelwithEnhancementAvailable()
	
	If Common.DataSeparationEnabled() Then
		If DigitalSignatureInternal.UseCloudSignatureService() Then
			
			TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
			ConnectionSettings = TheDSSCryptographyServiceModule.ServiceAccountConnectionSettings();
			
			Return ConnectionSettings.Completed2;
			
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Function CertificationAuthorityData(SearchValues) Export
	
	AccreditedCertificationCenters = DigitalSignatureInternalCached.AccreditedCertificationCenters();
	If AccreditedCertificationCenters = Undefined Then
		Return Undefined;
	EndIf;

	Return DigitalSignatureClientServerLocalization.CertificationAuthorityData(SearchValues, AccreditedCertificationCenters);
	
EndFunction

Function AccreditedCertificationCenters() Export
	
	AccreditedCertificationCenters = Undefined;
	DigitalSignatureLocalization.OnGetAccreditedCAs(AccreditedCertificationCenters);
	Return AccreditedCertificationCenters;
	
EndFunction

Function CARevocationListDirectories() Export
	
	AccreditedCertificationCenters = DigitalSignatureInternalCached.AccreditedCertificationCenters();
	ModuleDigitalSignatureClientServerLocalization = Common.CommonModule("DigitalSignatureClientServerLocalization");
	Return ModuleDigitalSignatureClientServerLocalization.CARevocationListDirectories(AccreditedCertificationCenters);
	
EndFunction

Function InstalledCryptoProviders() Export
	
	Return DigitalSignatureInternal.InstalledCryptoProviders();
	
EndFunction

Function SignatureVerificationAlgorithms(SettingToSupply)
	
	SignatureVerificationAlgorithms = SettingToSupply.SignatureVerificationAlgorithms;
	If SignatureVerificationAlgorithms.Find(SettingToSupply.SignAlgorithm) = Undefined Then
		SignatureVerificationAlgorithms.Insert(0, SettingToSupply.SignAlgorithm);
	EndIf;

	For Each SignAlgorithm In SettingToSupply.SignAlgorithms Do
		If SignatureVerificationAlgorithms.Find(SignAlgorithm) = Undefined Then
			SignatureVerificationAlgorithms.Add(SignAlgorithm);
		EndIf;
	EndDo;
	
	Return SignatureVerificationAlgorithms;
	
EndFunction

#EndRegion
