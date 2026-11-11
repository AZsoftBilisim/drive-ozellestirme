#Region Public

// Returns whether the extension folder is used in the app
//
// Returns:
//  Boolean
Function Used() Export
	
	Return False;
	
EndFunction

// Returns the name of the link to go to the extensions directory
//
// Returns:
//  String
Function NameOfExtensionCatalogLink() Export
	
	Return NStr("vi = 'Thư mục phần mở rộng';
				|ru = 'Каталог расширений';
				|en = 'Extension Store'; fa = 'فروشگاه افزونه';
				|it = 'Catalogo estensioni';
				|pl = 'Katalog rozszerzeń';
				|tr = 'Uzantı dizini'");
	
EndFunction

// Returns the current State of the extension
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  PublicId - String - public extension ID from the Service Manager
// 
// Returns:
//  EnumRef.ExtensionStates
Function ExtensionState(PublicId) Export
EndFunction


// Information about the user's rating.
// 
// Parameters:
//  PublicId - String - public extension ID from the Service Manager
// 
// Returns:
//  Structure - User Rating Information:
// * RatingIsSet - Boolean - flag that the user has set a rating
// * NameOfExtension - String - Name of the Extension
// * Evaluation - Number - numerical Presentation Of The score
// * CreationDate - Date - date of creation of the first assessment
// * LastChangeDate - Date - date of last rating change
// * Version - String - the version of the extension that was installed at the time of the last rating edit
// * DeveloperResponse - String - the text of the developer's response to the assessment
// * DateOfDeveloperResponse - Date - date of the developer's response to the assessment
// * ExtensionInstallationDate - Date - date the extension was installed in the app 
// * ReceivingDataError - Structure - if an error occurred when receiving data, then this property exists:
// ** ErrorText - String - Error Information Text
Function UserRatingInformation(PublicId) Export
	
	DataOfError = New Structure();
	DataOfError.Insert("ErrorText", NStr("vi = 'Chưa kết nối phần mở rộng fresh.';
										|ru = 'Расширение fresh не подключено.';
										|en = 'The ""fresh"" extension is not attached.'; fa = 'The ""fresh"" extension is not attached.';
										|it = 'Расширение fresh не подключено.';
										|pl = 'The ""fresh"" extension is not attached.';
										|tr = 'Fresh uzantısı bağlı değil'"));
	
	ResponseData = New Structure();
	ResponseData.Insert("RatingIsSet", False);
	ResponseData.Insert("NameOfExtension", "");
	ResponseData.Insert("Evaluation", 0);
	ResponseData.Insert("CreationDate", Date(1, 1, 1));
	ResponseData.Insert("LastChangeDate", Date(1, 1, 1));
	ResponseData.Insert("Version", "");
	ResponseData.Insert("DeveloperResponse", "");
	ResponseData.Insert("DateOfDeveloperResponse", Date(1, 1, 1));
	ResponseData.Insert("ExtensionInstallationDate", Date(1, 1, 1));
	ResponseData.Insert("ReceivingDataError", DataOfError);
	
	Return ResponseData;
	
EndFunction

// Changes the value of using the Extension Catalog in the application
// 
// Parameters:
//  Use - Boolean - required value for using the Extension Directory in the application
//
// Returns:
//  Boolean - if executed successfully, it returns the value True as the result
//@skip-check module-empty-method
Function ChangeUsageValueInApp(Use) Export
EndFunction

#EndRegion

#Region Internal

// Parameters:
//	InstalledExtensions_ - Array of Structure - with properties:
//		* Id - UUID - id of the extension in the service.
//		* Presentation - String - performance of the extension. 
//		* Installation - UUID - new installation id.
//		
// Returns:
// 	Boolean - True if successful, False otherwise.
//
Function RestoreExtensionsToNewArea(Val InstalledExtensions_, 
	Val ServiceUserID = Undefined) Export
	
	Return False;
	
EndFunction

// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  DataAreaCode - Number - 
//  
// Returns:
//	Structure - with properties:
//	 * DataAreaKey - String - 
//	 * RecoveryExtensions - See RestoreExtensionsToNewArea.InstalledExtensions_
//
Function GetExtensionsForNewArea(Val DataAreaCode) Export
EndFunction

// Returns: 
//  Array of Type - reference types added by extensions.
Function ReferenceTypesAddedByExtensions() Export
	
	ReferenceTypes = New Array;
	TypesOfMetadataObjectsOfReferenceType = TypesOfMetadataObjectsOfReferenceType();
	
	IsSeparatedSession = SaaSOperations.SessionSeparatorUsage();
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	SessionExtensions = ConfigurationExtensions.Get(,
		ConfigurationExtensionsSource.SessionApplied);
	
	ScopeSeparation = ConfigurationExtensionScope.DataSeparation;	
	For Each Extension In SessionExtensions Do
		
		If IsSeparatedSession And
			Extension.Scope <> ScopeSeparation Then
			Continue;
		EndIf;
		
		If Not Extension.ModifiesDataStructure() Then
			Continue;
		EndIf;
		
		OMDExtensions = New ConfigurationMetadataObject(Extension.GetData());
		
		For Each OMDType In TypesOfMetadataObjectsOfReferenceType Do
			AddTypes_(ReferenceTypes, OMDType, OMDExtensions);
		EndDo;
		
	EndDo;
	
	Return ReferenceTypes;
	
EndFunction

Procedure RecordDataOfRecoverableAreaExtensions(RecoveryExtensions) Export 
	
	Common.WriteDataToSecureStorage(
		"ExtensionData_", 
		RecoveryExtensions, 
		"RecoveryExtensions");
	
EndProcedure

Procedure ReadDataOfRecoverableAreaExtensions(ExtensionData_) Export 

	If TypeOf(ExtensionData_) <> Type("Structure") Then
		Return;
	EndIf;
	
	If ExtensionData_.Property("RecoveryExtensions") Then
		Return;
	EndIf;	
	
	StorageData = ReadDataOfRecoverableExtensions();
		
	If StorageData <> Undefined Then
		ExtensionData_.Insert("RecoveryExtensions", StorageData);	
	EndIf;
	
EndProcedure

Function ReadDataOfRecoverableExtensions() Export
	
	Return Common.ReadDataFromSecureStorage(
		"ExtensionData_",
		"RecoveryExtensions");
	
EndFunction

// @skip-check module-empty-method
// 
// Parameters:
//  NewValue - Boolean
Procedure OnChangeConstantUseExtensionCatalogInSaaS(Val NewValue) Export
EndProcedure

// Returns an indication that the extension catalog usage information database is supported.
// 
// Returns:
//  Boolean - indicates whether the extension catalog information database is supported
Function AvailableInInfobase() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Procedure AddTypes_(ReferenceTypes, OMDType, OMDExtensions)
	
	ObjectBelonging = Metadata.ObjectProperties.ObjectBelonging.Native; 
	
	For Each OMD In OMDExtensions[OMDType] Do
		
		If OMD.ObjectBelonging <> ObjectBelonging Then
			Continue;
		EndIf;
		
		ReferenceForTypeDefinition = PredefinedValue(OMD.FullName() 
			+ ".EmptyRef");
		ReferenceTypes.Add(TypeOf(ReferenceForTypeDefinition));
		
	EndDo;
	
EndProcedure

Function TypesOfMetadataObjectsOfReferenceType()
	
	TypesOfMetadataObjectsOfReferenceType = New Array;
	TypesOfMetadataObjectsOfReferenceType.Add("Catalogs");
	TypesOfMetadataObjectsOfReferenceType.Add("Documents");
	TypesOfMetadataObjectsOfReferenceType.Add("BusinessProcesses");
	TypesOfMetadataObjectsOfReferenceType.Add("Tasks");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfAccounts");
	TypesOfMetadataObjectsOfReferenceType.Add("ExchangePlans");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfCharacteristicTypes");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfCalculationTypes");
	
	Return TypesOfMetadataObjectsOfReferenceType;
	
EndFunction

#EndRegion