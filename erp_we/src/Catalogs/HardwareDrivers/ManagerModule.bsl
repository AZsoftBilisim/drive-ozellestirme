#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  FullObjectName - String - the name of the object to be filled in for.
//  Settings - Structure:
//    * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
//    * PredefinedData - ValueTable - the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnSetUpInitialItemsFilling(FullObjectName, Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// The procedure fills in predefined elements in the hardware driver directory.
//
// Parameters:
//  HardwareDrivers - ValueTable
//
Procedure OnInitialItemsFilling(HardwareDrivers) Export
	
	CurrentLanguage = CurrentLanguage();
	LanguageCode = ?(TypeOf(CurrentLanguage) = Type("String"), CurrentLanguage, CurrentLanguage.LanguageCode); 
	
	DriverTable = New ValueTable();
	DriverTable.Columns.Add("Ref");
	DriverTable.Columns.Add("PredefinedDataName");
	DriverTable.Columns.Add("InRegNameOfPredefinedData");
	DriverTable.Indexes.Add("InRegNameOfPredefinedData");
	DriverTable.Columns.Add("ConnectionMethod");
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	HardwareDrivers.Ref AS Ref,
		|	HardwareDrivers.PredefinedDataName AS PredefinedDataName,
		|	HardwareDrivers.ConnectionMethod AS ConnectionMethod
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	HardwareDrivers.PredefinedDataName IN(&ListOfNames)";
	
	Query.SetParameter("ListOfNames", HardwareDrivers.UnloadColumn("NameOfDriver"));
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		NewRow = DriverTable.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.InRegNameOfPredefinedData = Upper(NewRow.PredefinedDataName);
	EndDo;
	
	BeginTransaction();
	
	Try  
		
		Block = New DataLock();
		LockItem = Block.Add("Catalog.HardwareDrivers");
		LockItem.DataSource = DriverTable;
		LockItem.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		For Each HardwareDriver In HardwareDrivers Do
			
			DriverParameters = EquipmentManagerClientServer.ParametersForCreatingNewDriver();
			FillPropertyValues(DriverParameters, HardwareDriver);                           
			
			DriverParameters.Predefined = True;
			
			If TypeOf(DriverParameters.EquipmentType) = Type("String") Then     
				DriverParameters.EquipmentType = EquipmentManager.EquipmentTypeByLine(DriverParameters.EquipmentType);
			EndIf;
			
			TableRow = DriverTable.Find(Upper(DriverParameters.NameOfDriver),"InRegNameOfPredefinedData");
			If TableRow <> Undefined Then
				Driver = TableRow.Ref.GetObject();
				
				DriverParameters.ConnectionMethod = TableRow.ConnectionMethod;
				TemplateIsAvailable = False;                                
				DriverTemplateName = DriverParameters.DriverTemplateName;
				EquipmentManager.FillINTemplateData(DriverParameters.NameOfDriver, DriverTemplateName, TemplateIsAvailable, Undefined, LanguageCode); 
				If Not TemplateIsAvailable Then
					DriverParameters.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase;
				EndIf;
				
			Else
				Driver = Catalogs.HardwareDrivers.CreateItem();
				Driver.PredefinedDataName = DriverParameters.NameOfDriver;     
				
				
				TemplateIsAvailable = False;                                
				DriverTemplateName = DriverParameters.DriverTemplateName;
				EquipmentManager.FillINTemplateData(DriverParameters.NameOfDriver, DriverTemplateName, TemplateIsAvailable, Undefined, LanguageCode); 
				If Not ValueIsFilled(DriverParameters.ConnectionMethod) Then
					If TemplateIsAvailable Then
						DriverParameters.ConnectionMethod = Enums.DriverConnectionMethod.From_Template;
					Else                                                                   
						DriverParameters.ConnectionMethod = Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase;
					EndIf;
				EndIf;
			EndIf;
			
			If (Driver.Description <> DriverParameters.Description)
				Or (Driver.ObjectID <> String(DriverParameters.ObjectID))
				Or (Driver.DriverVersion <> String(DriverParameters.DriverVersion))
				Or (Driver.DriverTemplateName <> String(DriverParameters.DriverTemplateName))
				Or (Driver.EquipmentType <> DriverParameters.EquipmentType)
				Or (Driver.ConnectionMethod <> DriverParameters.ConnectionMethod)
				Or (Driver.NoLongerSupported <> DriverParameters.NoLongerSupported)        
				Or (Driver.SafeConnection <> DriverParameters.SafeConnection) 
				Or (Driver.RecommendedUse <> DriverParameters.RecommendedUse) Then 
				Driver.Description          = DriverParameters.Description;
				Driver.ObjectID  = DriverParameters.ObjectID;
				Driver.DriverVersion        = DriverParameters.DriverVersion;
				Driver.DriverTemplateName     = DriverParameters.DriverTemplateName;
				Driver.EquipmentType       = DriverParameters.EquipmentType;
				Driver.ConnectionMethod     = DriverParameters.ConnectionMethod;
				Driver.NoLongerSupported        = DriverParameters.NoLongerSupported;
				Driver.SafeConnection      = DriverParameters.SafeConnection; 
				Driver.RecommendedUse = DriverParameters.RecommendedUse;
				If Driver.NoLongerSupported Then  
					Driver.MessageWhenUsing = True;
				EndIf;
				Driver.Write();
			EndIf;
				
		EndDo;
		
		CommitTransaction(); 
		
	Except
		RollbackTransaction();    
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Điền phần tử định trước của driver';
				|ru = 'Заполнение предопределенных элементов драйвера';
				|en = 'Fill predefined driver items'; fa = 'Fill predefined driver items';
				|it = 'Compilazione elementi predefiniti del driver';
				|pl = 'Wypełnienie predefiniowanych elementów sterownika';
				|tr = 'Sürücünün önceden tanımlı öğelerini doldurmak'", CommonCEL.DefaultLanguageCode()));
	EndTry;
	
EndProcedure

// The procedure fills in an item in the hardware driver directory.
//
// Parameters:
//  CreationParameters - Structure - hardware creation parameters.
//
// Returns:
//  CatalogRef.HardwareDrivers - 
//
Function CreateNewItem(CreationParameters) Export
	
	NewItem = Catalogs.HardwareDrivers.CreateItem();
	
	If TypeOf(CreationParameters.EquipmentType) = Type("String") Then
		CreationParameters.EquipmentType = EquipmentManager.EquipmentTypeByLine(CreationParameters.EquipmentType);
	EndIf;
	
	NewItem.EquipmentType       = CreationParameters.EquipmentType;
	NewItem.ObjectID  = CreationParameters.ObjectID;
	NewItem.Description          = CreationParameters.Description;
	NewItem.DriverTemplateName     = CreationParameters.DriverTemplateName;
	NewItem.DriverVersion        = CreationParameters.DriverVersion;
	NewItem.NoLongerSupported        = CreationParameters.NoLongerSupported;
	NewItem.ConnectionMethod     = CreationParameters.ConnectionMethod; 
	NewItem.SafeConnection = CreationParameters.SafeConnection;
	If CreationParameters.Predefined Then
		NewItem.PredefinedDataName = CreationParameters.NameOfDriver;     
	EndIf;
	
	NewItem.Write();
	
	Return NewItem.Ref;
	
EndFunction

// Gets a reference to a predefined element by its full name.
//
// Parameters:
//  FullPredefinedItemName - String - name of the predefined element.
//
// Returns:
//  CatalogRef.Peripherals,
//  Undefined.
//
Function PredefinedItem(Val FullPredefinedItemName) Export
	
	PredefinedItemName = Upper(FullPredefinedItemName);
	
	Point = Find(PredefinedItemName, ".");
	CollectionName = Left(PredefinedItemName, Point - 1);
	PredefinedItemName = Mid(PredefinedItemName, Point + 1);
	
	Point = Find(PredefinedItemName, ".");
	TableName = Left(PredefinedItemName, Point - 1);
	PredefinedItemName = Mid(PredefinedItemName, Point + 1);
	
	QueryText = "SELECT ALLOWED TOP 1 Ref FROM &FullTableName WHERE PredefinedDataName = &PredefinedItemName";
	QueryText = StrReplace(QueryText, "&FullTableName", CollectionName + "." + TableName);
	
	Query = New Query(QueryText);
	Query.SetParameter("PredefinedItemName", PredefinedItemName);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		Return Result.Unload()[0].Ref;
	EndIf;
	
EndFunction

// The function returns a structure with hardware driver data
// (with the values of the details of the directory element).
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
// Returns:
//  Structure
//
Function HardwareDriverData(DriverID) Export
	
	CurrentLanguage = CurrentLanguage();
	LanguageCode = ?(TypeOf(CurrentLanguage) = Type("String"), CurrentLanguage, CurrentLanguage.LanguageCode); 
	
	DriverData = New Structure();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDriversOverridable.Ref AS Ref,
		|	HardwareDriversOverridable.Description AS Description,
		|	HardwareDriversOverridable.ObjectID AS ObjectID,
		|	HardwareDriversOverridable.DriverVersion AS DriverVersion,       
		|	HardwareDriversOverridable.DriverTemplateName AS DriverTemplateName,
		|	HardwareDriversOverridable.NoLongerSupported AS NoLongerSupported, 
		|	HardwareDriversOverridable.MessageWhenUsing AS MessageWhenUsing,
		|	HardwareDriversOverridable.PredefinedDataName AS PredefinedDataName,
		|	HardwareDriversOverridable.EquipmentType AS EquipmentType,
		|	HardwareDriversOverridable.Predefined AS Predefined,
		|	HardwareDriversOverridable.ConnectionMethod AS ConnectionMethod,  
		|	HardwareDriversOverridable.SafeConnection AS SafeConnection
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDriversOverridable
		|WHERE
		|	HardwareDriversOverridable.Ref = &Id";
	
	Query.SetParameter("Id", DriverID);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		// Fill in the device data structure.
		DriverData.Insert("Ref"                   , Selection.Ref);
		DriverData.Insert("Description"             , Selection.Description);
		DriverData.Insert("ObjectID"     , Selection.ObjectID);
		DriverData.Insert("DriverVersion"           , Selection.DriverVersion);
		DriverData.Insert("NoLongerSupported"           , Selection.NoLongerSupported);           
		DriverData.Insert("MessageWhenUsing", Selection.MessageWhenUsing);  
		DriverData.Insert("PredefinedDataName", Selection.PredefinedDataName);
		DriverData.Insert("TypesOfEquipment"         , EquipmentManager.ParametersTypesOfEquipment(Selection.EquipmentType));  
		DriverData.Insert("EquipmentType"          , Selection.EquipmentType);  
		DriverData.Insert("EquipmentTypeName"       , XMLString(Selection.EquipmentType));   
		DriverData.Insert("SafeConnection"    , Selection.SafeConnection);   
			
		ConnectionMethod = Selection.ConnectionMethod;
		ConnectingFromTemplate = ConnectionMethod = Enums.DriverConnectionMethod.From_Template;
		ConnectingLocallyById = ConnectionMethod = Enums.DriverConnectionMethod.DriverIsInstalledOnLocalComputer;
		
		LocalizationPattern = Undefined;    
		TemplateIsAvailable = False;
		NameOfDriver = Selection.PredefinedDataName;
		DriverTemplateName = Selection.DriverTemplateName;    
		If Not IsBlankString(NameOfDriver) Then
			EquipmentManager.FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, LocalizationPattern, LanguageCode); 
		EndIf;
	
		DriverData.Insert("ConnectionMethod"        , ConnectionMethod);
		DriverData.Insert("ConnectingFromTemplate"      , ConnectingFromTemplate);
		DriverData.Insert("ConnectingLocallyById", ConnectingLocallyById);
		DriverData.Insert("DriverTemplateName"  , DriverTemplateName);
		DriverData.Insert("TemplateIsAvailable"      , TemplateIsAvailable);
		DriverData.Insert("LocalizationPattern"  , LocalizationPattern);        
		TypesOfEquipment = EquipmentManager.AvailableTypesOfNonCertifiedEquipment();
		If TypesOfEquipment.Find(Selection.EquipmentType) = Undefined Then
			NonCertified = False;
		Else
			NonCertified = True;
		EndIf;
		DriverData.Insert("NonCertified"  , NonCertified);
		
	EndDo;
	
	Return DriverData;
	
EndFunction

// The function returns drivers by hardware type
//
// Parameters:
//  EquipmentType - EnumRef.PeripheralTypes - Types of connected equipment.
//  OnlyAvailable - Boolean - indicates only available drivers.
//  RemovedFromDriverSupport - Boolean - indicates whether drivers removed from support are displayed.       
//  Only recommended use - Boolean - indicates that only recommended drivers are displayed.
//
// Returns:
//  Array of CatalogRef.HardwareDrivers
//
Function Drivers_ByHardwareType(EquipmentType, OnlyAvailable = True, RemovedFromDriverSupport = False, RecommendedUse = True) Export
	
	ListOfDrivers = New ValueList();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDriversOverridable.Ref AS Ref,
		|	HardwareDriversOverridable.Description AS Description,
		|	HardwareDriversOverridable.EquipmentType AS EquipmentType,
		|	HardwareDriversOverridable.Predefined AS Predefined
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDriversOverridable
		|WHERE
		|	HardwareDriversOverridable.EquipmentType = &EquipmentType
		|	AND (NOT &OnlyAvailable
		|			OR NOT HardwareDriversOverridable.DeletionMark)
		|	AND (&RemovedFromSupport
		|			OR NOT HardwareDriversOverridable.NoLongerSupported)
		|	AND (NOT &RecommendedUse 
		|			OR HardwareDriversOverridable.RecommendedUse)
		|
		|ORDER BY
		|	HardwareDriversOverridable.Description";
			
	Query.SetParameter("OnlyAvailable" ,  OnlyAvailable); 
	Query.SetParameter("RemovedFromSupport", RemovedFromDriverSupport);     
	Query.SetParameter("RecommendedUse", RecommendedUse);     
	Query.SetParameter("EquipmentType" , EquipmentType); 
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		ListOfDrivers.Add(SelectionDetailRecords.Ref, SelectionDetailRecords.Description);
	EndDo;
	
	Return ListOfDrivers;
	
EndFunction

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "Catalog.HardwareDrivers";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndRegion

#Region Internal

// Returns an array of IDs of all Library drivers 
// 
// Returns:
//   Array of String - array containing driver IDs
Function DriverIds() Export
	
	SetPrivilegedMode(True);
	
	IDs = New Array();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDrivers.ObjectID AS Id
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	HardwareDrivers.Predefined
		|	AND NOT HardwareDrivers.NoLongerSupported";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		IDs.Add(Selection.Id);
	EndDo;
	
	EquipmentManagerServerCallOverridable.WhenGettingDriverIds(IDs);
	
	Return IDs;
	
EndFunction

Procedure RegisterNonCertifiedDrivers(HardwareDrivers) Export
	
	// ++ Non-mobile application
	If Not CommonCEL.NonCertifiedEquipmentIsUsed() Then
		Return 
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDrivers.Ref AS Ref,
		|	HardwareDrivers.Description AS Description,
		|	HardwareDrivers.EquipmentType AS EquipmentType,
		|	HardwareDrivers.ObjectID AS ObjectID,
		|	HardwareDrivers.DriverVersion AS DriverVersion,
		|	HardwareDrivers.DriverTemplateName AS DriverTemplateName,
		|	HardwareDrivers.NetworkMode AS NetworkMode,
		|	HardwareDrivers.ServerMode AS ServerMode,
		|	HardwareDrivers.NoLongerSupported AS NoLongerSupported,
		|	HardwareDrivers.LocalMode_ AS LocalMode_
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	HardwareDrivers.EquipmentType IN(&TypesOfOtherEquipment)";
	
	TypesOfEquipment =  EquipmentManager.AvailableTypesOfNonCertifiedEquipment();
	Query.SetParameter("TypesOfOtherEquipment", TypesOfEquipment);
	

	Result = Query.Execute();
	DriverTable = Result.Unload();
	
	For Each Driver In HardwareDrivers Do // Structure
		
		If Not DriverAttributesFilledIn(Driver) Then
			#If Not MobileAppServer Then
				MessageText = NStr("vi = 'Chưa điền đúng mục tin của driver ""%1"".
				|Để đăng ký, cần điền: Kiểu thiết bị, Tên gọi, ID đối tượng, Tên khuôn in.';
				|ru = 'Не корректно заполнены реквизиты драйвера ""%1"".
				|Для регистрации должны быть заполнены: Тип оборудования, Наименование, Идентификатор объекта, Имя макета.';
				|en = 'The ""%1"" driver attributes are incorrectly filled out.
				|For registration, fill out: Equipment type, Description, Object ID, Template name.'; fa = 'The ""%1"" driver attributes are incorrectly filled out.
				|For registration, fill out: Equipment type, Description, Object ID, Template name.';
				|it = 'Не корректно заполнены реквизиты драйвера ""%1"".
				|Для регистрации должны быть заполнены: Тип оборудования, Наименование, Идентификатор объекта, Имя макета.';
				|pl = 'The ""%1"" driver attributes are incorrectly filled out.
				|For registration, fill out: Equipment type, Description, Object ID, Template name.';
				|tr = '""%1"" sürücüsünün öznitelikleri doğru doldurulmamış.
				|Kayıt için şunlar doldurulmalıdır: Ekipman türü, Tanımı, Nesne tanımlayıcısı, Şablon adı.'");
				MessageText = StrTemplate(MessageText, Driver.Description);
				ModuleNonCertifiedEquipmentClientServer = CommonCEL.CommonModule("UncertifiedPeripheralsClientServer");
				WriteLogEvent(ModuleNonCertifiedEquipmentClientServer.EventLogEvent(),
				EventLogLevel.Error,,, MessageText);
			#EndIf
			Continue;
		EndIf;
		
		String = DriverTable.Find(Driver.ObjectID, "ObjectID");
		If String = Undefined Then
			DriverObject = Catalogs.HardwareDrivers.CreateItem();
			FillPropertyValues(DriverObject, Driver);
			DriverObject.ConnectionMethod = Enums.DriverConnectionMethod.From_Template;
			DriverObject.Write();
		Else
			If ObjectsAreIdentical(String, Driver, Result.Columns, "Ref") Then
				Continue;
			EndIf;
			DriverObject = String.Ref.GetObject();
			FillPropertyValues(DriverObject, Driver);
			DriverObject.Write();
		EndIf
	EndDo;
	// -- Non-mobile application
	
EndProcedure

#EndRegion

// ++ Non-mobile application
#Region Private

Function ObjectsAreIdentical(Object1, Object2, Columns, Exceptions = "")
	
	ExceptionsArray = StrSplit(Exceptions, ",", False);
	For Each Field In Columns Do
		FieldName = TrimAll(Field.Name);
		If ExceptionsArray.Find(FieldName)<>Undefined Then
			Continue;
		EndIf;
		If Object1[FieldName] <> Object2[FieldName] Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Parameters:
//  Driver - Structure
//
// Returns:
//  Boolean
Function DriverAttributesFilledIn(Driver)
	
	Return ValueIsFilled(Driver.EquipmentType) And
		ValueIsFilled(Driver.Description) And
		ValueIsFilled(Driver.ObjectID) And
		ValueIsFilled(Driver.DriverTemplateName);
	
EndFunction

#EndRegion                
// -- Non-mobile application

#EndIf