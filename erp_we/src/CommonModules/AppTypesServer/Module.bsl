
#Region Public

// Returns a table of configuration application types.
// 
// Parameters:
//  IncludingBasic - Boolean - True if you need to include the basic view of the application in the table. 
//                            Default = True.
// 
// Returns:
//  ValueTable - See NewAppTypesTable
//
Function ConfigurationAppTypes(IncludingBasic = True) Export
	
	AppTypes = NewAppTypesTable();
	
	If IncludingBasic Then
		BasicAppType = BasicAppType();
		NewAppType = AppTypes.Add();
		
		FillPropertyValues(NewAppType, BasicAppType);
		NewAppType.AdditionalProperties = New Structure(BasicAppType.AdditionalProperties);
	EndIf;
	
	AppTypesOverridable.OnDefineConfigurationAppTypes(AppTypes);
	
	Return AppTypes;
	
EndFunction

// Returns a table of transition handlers for types of configuration applications
// 
// Returns:
//  ValueTable - See NewUpgradeHandlersTable
//
Function UpgradeHandlers() Export
	
	MigrationHandlers = NewUpgradeHandlersTable();
	AppTypesOverridable.OnAddHandlersUpgradeAppType(MigrationHandlers);
	
	Return MigrationHandlers;
	
EndFunction

// Returns a table of traffic handlers from the application view
// 
// Parameters:
//  AppTypeOriginalName - String - name of the previous application view
//  AppTypeName - String, Undefined - name of the new app type. Undefined - if the new type of application is any. 
//                                             By default, Undefined
// 
// Returns:
//  ValueTable - See NewUpgradeHandlersTable
//
Function AppTypeUpgradeHandlers(AppTypeOriginalName, AppTypeName = Undefined) Export
	
	Result = NewUpgradeHandlersTable();
	
	Filter = New Structure("AppTypeOriginalName", AppTypeOriginalName);
	If AppTypeName <> Undefined Then
		Filter.Insert("AppTypeName", AppTypeName);
	EndIf;
	
	FoundRows = UpgradeHandlers().FindRows(Filter); 
	For Each NavigationRow In FoundRows Do
		FillPropertyValues(Result.Add(), NavigationRow);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the name of the configuration application view, autonomous workstation (APM), or data area if partitioning is enabled
// 
// Returns:
//  String - name of the Cur view of the application
// 
// Note:
//  The name of the application type for the ARM may differ from the final one if the function was accessed before the End of uploading data to the ARM
//
Function CurrentAppTypeName() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		DataAreaAppType = InformationRegisters.DataAreasAppTypes.CreateRecordManager();
		DataAreaAppType.Read();
		
		Return DataAreaAppType.AppTypeName;
	EndIf;
	
	CurrentAppTypeName = BasicAppType().Name;
	
	If GetFunctionalOption("StandaloneWorkplace") Then
		CurrentAppTypeName = Constants.StandaloneWorkstationAppTypeName.Get();
	EndIf;
	
	AppTypeParameters = Common.ReadDataFromSecureStorage(
		AppTypeId(), AppTypeParametersKey());
	If AppTypeParameters <> Undefined Then
		AppTypesOverridable.OnGetCurrentAppTypeName(
			AppTypeParameters.Name, CurrentAppTypeName);
	EndIf;
	
	Return CurrentAppTypeName;
	
EndFunction

// Returns a Presentation of the configuration application view, autonomous workstation (APM), or data area, if partitioning is enabled
//
// Returns:
//  String - Presentation of the application view
//
// Note:
//  The Presentation of the application view for the ARM may differ from the final one if the function was accessed before the End of loading data into the ARM
//
Function CurrentAppTypePresentation() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled() 
		And Common.SeparatedDataUsageAvailable() Then
		
		DataAreaAppType = InformationRegisters.DataAreasAppTypes.CreateRecordManager();
		DataAreaAppType.Read();
		
		Return DataAreaAppType.AppTypePresentation;
		
	EndIf;
	
	CurrentAppTypePresentation = BasicAppType().Presentation;
	
	If GetFunctionalOption("StandaloneWorkplace") Then
		CurrentAppTypePresentation = Constants.StandaloneWorkstationAppTypePresentation.Get();
	EndIf;
	
	AppTypeParameters = Common.ReadDataFromSecureStorage(
		AppTypeId(), AppTypeParametersKey());
	If AppTypeParameters <> Undefined Then
		CurrentAppTypePresentation = AppTypeParameters.Presentation;
	EndIf;
	
	Return CurrentAppTypePresentation;
	
EndFunction

// Returns properties of the application view by name.
// 
// Parameters:
//  Name - String - name of the application type whose properties you want to get.
//  RaiseException1 - Boolean - if False, then if there are no properties of the application view by name
//                                , the exception will not be raised. Default = True.
// 
// Returns:
//  Undefined, FixedStructure - Properties of the application view.
//                                         If the properties are not found and call an exception = False, returns Indefinite.
//                                         For the list of properties, see the Serverviewapplication.Newapplications.
//
Function AppTypePropertiesByName(Name, RaiseException1 = True) Export
	
	AppTypes = ConfigurationAppTypes();
	FoundRows = AppTypes.FindRows(New Structure("Name", Name));
	
	MessageText = "";
	If FoundRows.Count() = 0 Then
		MessageText = StrTemplate(
			NStr("vi = 'Chưa tìm thấy dạng ứng dụng theo tên ""%1""';
				|ru = 'Не найден вид приложения по имени ""%1""';
				|en = 'Cannot find application type by name ""%1""'; fa = 'Cannot find application type by name ""%1""';
				|it = 'Не найден вид приложения по имени ""%1""';
				|pl = 'Cannot find application type by name ""%1""';
				|tr = '""%1"" adlı uygulama türü bulunamadı'"), Name);
	ElsIf FoundRows.Count() > 1 Then
		MessageText = StrTemplate(
			NStr("vi = 'Đã tìm thấy một số dạng ứng dụng theo tên ""%1""';
				|ru = 'Найдено несколько видов приложений по имени ""%1""';
				|en = 'Multiple application types found by name ""%1""'; fa = 'Multiple application types found by name ""%1""';
				|it = 'Найдено несколько видов приложений по имени ""%1""';
				|pl = 'Multiple application types found by name ""%1""';
				|tr = '""%1"" adlı birden fazla uygulama türü bulundu'"), Name);
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		WriteLogEvent(
			NStr("vi = 'Dạng ứng dụng. Tìm kiếm dạng ứng dụng';
				|ru = 'Виды приложений. Поиск вида приложения';
				|en = 'Application types. Search for application type'; fa = 'Application types. Search for application type';
				|it = 'Виды приложений. Поиск вида приложения';
				|pl = 'Application types. Search for application type';
				|tr = 'Uygulama türleri. Uygulama türü arama'", Common.DefaultLanguageCode()),
			EventLogLevel.Warning, , , MessageText);
		
		If RaiseException1 Then
			Raise MessageText;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	Return Common.FixedData(
		Common.ValueTableRowToStructure(FoundRows[0]));
	
EndFunction

// Returns properties of the Services application view.
// The search is based on the full compliance of the services in the passed parameter and the description of the application type
// 
// Parameters:
//  Services - ValueTable - LongDesc SeeNewServicesTable
//  RaiseException1 - Boolean - if False, then if there are no properties of the application type by services 
//                                , an exception will not be raised. By default, True.
// 
// Returns:
//  Undefined, FixedStructure - Properties of the application view.
//                                         If the properties are not found and call an exception = False, returns Indefinite.
//                                         For the list of properties, see the Serverviewapplication.Newapplications.
//
Function AppTypePropertiesByServices(Services, RaiseException1 = True) Export
	
	FoundRows = New Array;
	
	AppTypes = ConfigurationAppTypes();
	For Each ApplicationKind In AppTypes Do
		AppTypeServices = ApplicationKind.Services;
		
		If AppTypeServices.Count() <> Services.Count() Then
			Continue;
		EndIf;
		
		AllServicesFound = True;
		For Each OperationService In Services Do
			If Not ServiceFoundInAppType(ApplicationKind, OperationService) Then
				AllServicesFound = False;
				Break;
			EndIf;
		EndDo;
		
		If AllServicesFound Then
			FoundRows.Add(ApplicationKind);
		EndIf;
	EndDo;
	
	MessageText = "";
	If FoundRows.Count() = 0 Then
		MessageText = StrTemplate(
			NStr("vi = 'Chưa tìm thấy dạng ứng dụng theo danh sách dịch vụ: %1';
				|ru = 'Не найден вид приложения по списку услуг: %1';
				|en = 'Cannot find application type by service list: %1'; fa = 'Cannot find application type by service list: %1';
				|it = 'Не найден вид приложения по списку услуг: %1';
				|pl = 'Cannot find application type by service list: %1';
				|tr = 'Hizmetler listesine göre uygulama türü bulunamadı: %1'"),
			ServicesListPresentation(Services, Chars.LF + "- "));
	ElsIf FoundRows.Count() > 1 Then
		MessageText = StrTemplate(
			NStr("vi = 'Đã tìm thấy một số dạng ứng dụng theo danh sách dịch vụ:%1';
				|ru = 'Найдено несколько видов приложений по списку услуг:%1';
				|en = 'Multiple application types found by service list: %1'; fa = 'Multiple application types found by service list: %1';
				|it = 'Найдено несколько видов приложений по списку услуг:%1';
				|pl = 'Multiple application types found by service list: %1';
				|tr = 'Hizmet listesine göre birden fazla uygulama türü bulundu:%1'"),
			ServicesListPresentation(Services, Chars.LF + "- "));
	EndIf;
	
	If ValueIsFilled(MessageText) Then
		WriteLogEvent(
			NStr("vi = 'Dạng ứng dụng. Tìm kiếm dạng ứng dụng';
				|ru = 'Виды приложений. Поиск вида приложения';
				|en = 'Application types. Search for application type'; fa = 'Application types. Search for application type';
				|it = 'Виды приложений. Поиск вида приложения';
				|pl = 'Application types. Search for application type';
				|tr = 'Uygulama türleri. Uygulama türü arama'", Common.DefaultLanguageCode()),
			EventLogLevel.Warning, , , MessageText);
		
		If RaiseException1 Then
			Raise MessageText;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	Return Common.FixedData(
		Common.ValueTableRowToStructure(FoundRows[0]));
	
EndFunction

// Returns the application view corresponding to the configuration.
// 
// Returns:
//  FixedStructure - See NewAppType
//
Function BasicAppType() Export
	
	ApplicationKind = NewAppType();
	ApplicationKind.Name = Metadata.Name;
	ApplicationKind.Presentation = Metadata.Presentation();
	ApplicationKind.Basic = True;
	ApplicationKind.Procedure = "AppTypesInternal.InstallingBasicAppType";
	
	AppTypesOverridable.OnDefineBasicAppTypeAddProperties(ApplicationKind.AdditionalProperties);
	
	Return Common.FixedData(ApplicationKind);
	
EndFunction

// Returns the application view that will be installed by default 
// if, for example, it was not possible to define the application view by name or services.
// 
// Returns:
//  FixedStructure - See NewAppType
//
Function DefaultAppType() Export
	
	ApplicationKind = Undefined;
	
	AppTypesOverridable.OnDefineDefaultAppType(ApplicationKind);
	If ApplicationKind = Undefined Then
		ApplicationKind = BasicAppType();
	EndIf;
	
	Return Common.FixedData(ApplicationKind);
	
EndFunction

// Saves the application view parameters to a secure storage.
//
// Parameters:
//  Parameters - Undefined, Structure - if Undefined, the saved application view parameters are deleted:
//   * Name - String - The name of the application type, no more than 255 characters long.
//   * NameOfUser - String - The name of the custom application view, no more than 255 characters long.
//   * Presentation - String - Presentation of the application view, no more than 150 characters long.
//
// Note:
//  The application view parameters will not be saved if the application viewname is not in the Server Application View table.Configuration Application view.
//
Procedure SetAppTypeParameters(Parameters) Export
	
	//@skip-check unavailable-in-safemode
	SetPrivilegedMode(True);
	
	If Parameters = Undefined Then
		MessageText = NStr("vi = 'Đã xóa tham số';
							|ru = 'Параметры удалены';
							|en = 'Parameters are deleted'; fa = 'Parameters are deleted';
							|it = 'Parameters are deleted';
							|pl = 'Parameters are deleted';
							|tr = 'Parametreler silindi'");
		
		Common.DeleteDataFromSecureStorage(
			AppTypeId(), AppTypeParametersKey());
		
	ElsIf ConfigurationAppTypes().Find(Parameters.Name, "Name") = Undefined Then
		MessageText = StrTemplate(
			NStr("vi = 'Chưa tìm thấy tên dạng ứng dụng ""%1"" trong bảng dạng ứng dụng cấu hình. Đã xóa tham số';
				|ru = 'Имя вида приложения ""%1"" не найдено в таблице видов приложений конфигурации. Параметры удалены';
				|en = 'The ""%1"" application type name is not found in the configuration application type table. Parameters are deleted'; fa = 'The ""%1"" application type name is not found in the configuration application type table. Parameters are deleted';
				|it = 'The ""%1"" application type name is not found in the configuration application type table. Parameters are deleted';
				|pl = 'The ""%1"" application type name is not found in the configuration application type table. Parameters are deleted';
				|tr = '""%1"" uygulama türü adı konfigürasyon uygulama türü tablosunda bulunmamaktadır. Parametreler silindi'"), Parameters.Name);
		
		Common.DeleteDataFromSecureStorage(
			AppTypeId(), AppTypeParametersKey());
		
	Else
		MessageText = StrTemplate(
			NStr("vi = 'Tên dạng ứng dụng: %2%1Trình bày dạng ứng dụng: %3%1Tên dạng ứng dụng tự tạo:%4';
				|ru = 'Имя вида приложения: %2%1Представление вида приложения: %3%1Имя вида приложения пользовательское:%4';
				|en = 'Application type name: %2%1Application type presentation: %3%1User application type name:%4'; fa = 'Application type name: %2%1Application type presentation: %3%1User application type name:%4';
				|it = 'Application type name: %2%1Application type presentation: %3%1User application type name:%4';
				|pl = 'Application type name: %2%1Application type presentation: %3%1User application type name:%4';
				|tr = 'Uygulama türünün adı: %2%1Uygulama türünün gösterimi: %3%1Uygulama türünün kullanıcı adı:%4'"),
			Chars.LF, Parameters.Name, Parameters.Presentation, Parameters.NameOfUser);
		
		AppTypeData = New Structure();
		AppTypeData.Insert("Name", Parameters.Name);
		AppTypeData.Insert("Presentation", Parameters.Presentation);
		AppTypeData.Insert("NameOfUser", Parameters.NameOfUser);
		
		Common.WriteDataToSecureStorage(
			AppTypeId(), AppTypeData, AppTypeParametersKey());
		
	EndIf;
	
	WriteLogEvent(
			NStr("vi = 'Dạng ứng dụng. Thay đổi tham số';
				|ru = 'Виды приложений. Изменение параметров';
				|en = 'Application types. Change parameters'; fa = 'Application types. Change parameters';
				|it = 'Application types. Change parameters';
				|pl = 'Application types. Change parameters';
				|tr = 'Uygulama türleri. Parametre değişikliği'", Common.DefaultLanguageCode()),
			EventLogLevel.Information, , , MessageText);
	
EndProcedure

#EndRegion

#Region Internal

// Returns the name of the custom application view of the data area
// 
// Returns:
//  String - name of the Cur user view of the Cur application
// 
Function CurrentCustomAppTypeName() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		DataAreaAppType = InformationRegisters.DataAreasAppTypes.CreateRecordManager();
		DataAreaAppType.Read();
		
		Return DataAreaAppType.AppTypeNameCustom;
	EndIf;
	
	AppTypeParameters = Common.ReadDataFromSecureStorage(
		AppTypeId(), AppTypeParametersKey());
	If AppTypeParameters <> Undefined Then
		Return AppTypeParameters.NameOfUser;
	EndIf;
	
	Return "";
	
EndFunction

// Defines an array of extension names for the types of applications that will be excluded from uploading
//
// Parameters:
//  ExtensionNames - Array of String
//
Procedure AppTypesExtensionNames(ExtensionNames) Export
	AppTypesOverridable.OnDefineAppTypesExtensionNames(ExtensionNames);
EndProcedure

// Returns a template for describing the application view.
// 
// Returns:
//  Structure:
// * Name - String - name of the application type.
// * Presentation - String - Presentation of the application view.
// * Procedure - String - the full name of the handler procedure with the processing result parameter (See AppTypesServer.NewProcessingResult)
//                        .
//                        The handler is executed when the application view of the data area is filled in.
//                        It must be export.
// * Services - Array of See AppTypesServer.NewService - an array of services that can be used to determine the type of application.
//                                                             The set of services for each type of application must be unique.
//                                                             For the Basic type of application, the array of services is empty.
// * AdditionalProperties - Structure - additional properties for the application type.
//                                        It may not be filled in.
// * Basic - Boolean - for internal use.
//                      True if the application view matches the configuration.
//                      There can be only one basic application view. By default, False.
//
Function NewAppType() Export
	
	NewAppType = New Structure();
	NewAppType.Insert("Name", "");
	NewAppType.Insert("Presentation", "");
	NewAppType.Insert("Basic", False);
	NewAppType.Insert("Procedure", "");
	NewAppType.Insert("Services", New Array);
	NewAppType.Insert("AdditionalProperties", New Structure);
	
	Return NewAppType;
	
EndFunction

// Returns a description of the configuration application types table
// 
// Returns:
//  ValueTable - list of types of applications:
//   * Name - String - name of the application type.
//   * Presentation - String - Presentation of the application view.
//   * Procedure - String - the full name of the handler procedure with the processing result parameter (See AppTypesServer.NewProcessingResult)
//                          .
//                          The handler is executed when the application view of the data area is filled in.
//                          It must be export.
//   * Services - Array of See AppTypesServer.NewService - an array of services that can be used to determine the type of application.
//                                                               The set of services for each type of application must be unique.
//                                                               For the Basic type of application, the array of services is empty.
//   * AdditionalProperties - Structure - additional properties for the application type.
//                                          It may not be filled in.
//   * Basic - Boolean - for internal use.
//                        True if the application view matches the configuration.
//                        There can be only one basic application view. By default, False.
//
Function NewAppTypesTable() Export
	
	AppTypes = New ValueTable;
	AppTypes.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(255)));
	AppTypes.Columns.Add("Presentation", New TypeDescription("String", , New StringQualifiers(150)));
	AppTypes.Columns.Add("Procedure", New TypeDescription("String", , New StringQualifiers(0)));
	AppTypes.Columns.Add("Basic", New TypeDescription("Boolean"));
	AppTypes.Columns.Add("Services", New TypeDescription("Array"));
	AppTypes.Columns.Add("AdditionalProperties", New TypeDescription("Structure"));
	
	Return AppTypes;
	
EndFunction

// Returns a template for the service description of the application type
// 
// Returns:
//  Structure - New Service:
// * ServiceID - String - unique string identifier (code) of the service in the service.
// * VendorID - String - unique string identifier (code) of the service provider in the service.
//
Function NewService() Export
	
	NewService = New Structure();
	NewService.Insert("ServiceID", "");
	NewService.Insert("VendorID", "");
	
	Return NewService;
	
EndFunction

// Returns a description of the services table for the application types
// 
// Returns:
//  ValueTable - list of services of the application type:
//   * ServiceID - String - unique string identifier (code) of the service in the service.
//   * VendorID - String - unique string identifier (code) of the service provider in the service.
//
Function NewServicesTable() Export
	
	AppTypesServices = New ValueTable;
	AppTypesServices.Columns.Add("VendorID", New TypeDescription("String", , New StringQualifiers(50)));
	AppTypesServices.Columns.Add("ServiceID", New TypeDescription("String", , New StringQualifiers(50)));
	
	Return AppTypesServices;
	
EndFunction

// Returns a description of the table of transition handlers for one type of application to another
//
// Returns:
//  ValueTable:
//    * AppTypeOriginalName - String - The name of the application type that the transition is being made from.
//    * AppTypeName           - String - the name of the application type to which the transition is performed.
//    * Procedure                   - String - full name of the transition handler procedure.
//                                             It must be export.
//
Function NewUpgradeHandlersTable() Export
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("AppTypeOriginalName", New TypeDescription("String", , New StringQualifiers(255)));
	Handlers.Columns.Add("AppTypeName", New TypeDescription("String", , New StringQualifiers(255)));
	Handlers.Columns.Add("Procedure", New TypeDescription("String", New StringQualifiers(0)));
	
	Return Handlers;
	
EndFunction

// Returns a template for describing the processing result
// 
// Returns:
//  Structure:
//   * Error - Boolean - indicates a processing error. By default, False.
//   * Message - String - processing error message.
//
Function NewProcessingResult() Export
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("Error", False);
	ProcessingResult.Insert("Message", "");
	
	Return ProcessingResult;
	
EndFunction

// Returns template for app view update notification parameters.
// 
// Returns:
//  Structure:
// * Show - Boolean - True if you need to show the notification to active users. By default, False.
// * Title - String - the text of the notification.
// * Message - String - explanation of the notification.
// * ActionOnClick - Undefined, String, CallbackDescription - a navigation link in a row or a description of the procedure when clicked.
//                        By default, Undefined 
//
Function NewFinishUpgradeNotificationSettings() Export
	
	NoticeParameters = New Structure;
	NoticeParameters.Insert("Show", False);
	NoticeParameters.Insert("Title", NStr("vi = 'Đang thực hiện chuyển đến dạng ứng dụng mới';
											|ru = 'Выполнен переход на новый вид приложения';
											|en = 'Migration to new application type completed'; fa = 'Migration to new application type completed';
											|it = 'Выполнен переход на новый вид приложения';
											|pl = 'Migration to new application type completed';
											|tr = 'Yeni uygulama türüne geçiş yapıldı'"));
	NoticeParameters.Insert("Message", NStr("vi = 'Để áp dụng thay đổi, nên khởi động lại chương trình.';
											|ru = 'Для применения изменений требуется перезапустить программу.';
											|en = 'To apply the changes, restart the application.'; fa = 'To apply the changes, restart the application.';
											|it = 'Per applicare le modifiche è necessario riavviare il programma.';
											|pl = 'Aby zastosować zmiany, należy zrestartować program.';
											|tr = 'Değişikliklerin uygulanması için program yeniden başlatılmalıdır.'"));
	NoticeParameters.Insert("ActionOnClick", Undefined);
	
	Return NoticeParameters;
	
EndFunction

#EndRegion

#Region Private

// Checks the availability of the service in the description of the application type
// 
// Parameters:
//  ApplicationKind - See NewAppType
//  ServiceArguments - ValueTableRow of See AppTypesServer.NewServicesTable
// 
// Returns:
//  Boolean - True if the service is found in the application view data, False otherwise.
//
Function ServiceFoundInAppType(ApplicationKind, ServiceArguments)
	
	For Each OperationService In ApplicationKind.Services Do
		If OperationService.VendorID = ServiceArguments.VendorID
			And OperationService.ServiceID = ServiceArguments.ServiceID Then
			
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ServicesListPresentation(Services, Separator)
	
	Result = "";
	For Each OperationService In Services Do
		Result = Result + Separator + StrTemplate(
			NStr("vi = 'tên định danh nhà cung cấp: %1, tên định danh dịch vụ: %2';
				|ru = 'идентификатор поставщика: %1, идентификатор услуги: %2';
				|en = 'Provider ID: %1. Service ID: %2'; fa = 'Provider ID: %1. Service ID: %2';
				|it = 'идентификатор поставщика: %1, идентификатор услуги: %2';
				|pl = 'Provider ID: %1. Service ID: %2';
				|tr = 'tedarikçi kimliği: %1, hizmet kimliği: %2'"),
			OperationService.VendorID,
			OperationService.ServiceID);
	EndDo;
	
	Return Result;
	
EndFunction

Function AppTypeId()
	Return "ApplicationKind";
EndFunction

Function AppTypeParametersKey()
	Return "AppTypeParameters";
EndFunction

#EndRegion