#Region Public

// Returns the version of the library " 1C:Service technology library"
//
// Returns:
//  String - the version of the library in the format PP.{P|PP}.ZZ.SS.
//
Function LibraryVersion() Export
	
	Return "2.0.15.30";
	
EndFunction

// Returns the version of the library extension " 1C: Service Technology Library"
//
// Returns:
//  String, Undefined - library extension version or Undefined if the extension is not installed or not active 
//
Function LibraryExtensionVersion() Export

	Extensions = ConfigurationExtensions.Get(New Structure("Name", "fresh"),
		ConfigurationExtensionsSource.SessionApplied);

	If Not ValueIsFilled(Extensions) Then
		Return Undefined;
	EndIf;

	Return Extensions[0].Version;

EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Event handlers for BSP subsystems

// Called when data separation by data area is enabled.
//
Procedure OnEnableSeparationByDataAreas() Export
	
	CheckIfConfigurationCanBeUsedInServiceModel();
	
EndProcedure

// Adds to the list of procedure Handlers-update
// handlers required by this subsystem.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure RegisterUpdateHandlers(Handlers) Export
	
	If Common.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "CloudTechnology.CheckIfConfigurationCanBeUsedInServiceModel";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
	EndIf;
	
EndProcedure

// Checks whether the configuration can be used in the service model.
//  If it can't be used, an exception is thrown indicating the reason
//  why the configuration cannot be used in the service model.
//
Procedure CheckIfConfigurationCanBeUsedInServiceModel() Export
	
	SubsystemsDetails = Common.SubsystemsDetails(); // Array of Structure
	DetailsSSL = Undefined;
	
	For Each SubsystemDetails In SubsystemsDetails Do
		
		If SubsystemDetails.Name = "StandardSubsystems" Then
			
			DetailsSSL = SubsystemDetails;
			Break;
			
		EndIf;
		
	EndDo;
	
	If DetailsSSL = Undefined Then
		
		Raise StrTemplate(
			NStr("vi = 'Cấu hình không bao gồm thư viện ""1C: Thư viện Công nghệ Dịch vụ"".
                  |Không có thư viện này, không thể sử dụng cấu hình trong mô hình dịch vụ.
                  |
                  |Để sử dụng cấu hình này trong mô hình dịch vụ, bạn cần triển khai 
                  |"" 1C: Thư viện hệ thống con chuẩn ""nhỏ hơn %1';
                  |ru = 'В конфигурацию не внедрена библиотека ""1С:Библиотека стандартных подсистем"".
                  |Без внедрения этой библиотеки конфигурация не может использоваться в модели сервиса.
                  |
                  |Для использования этой конфигурации в модели сервиса требуется внедрить библиотеку
                  |""1С:Библиотека стандартных подсистем"" версии не младше %1';
                  |en = 'To run 1C:Enterprise applications in SaaS mode,
                  |Standard Subsystems Library (SSL) is required.
                  |The application you are using is missing SSL.
                  |To run the application in SaaS mode,
                  |install SSL version %1 or higher.'; fa = 'To run 1C:Enterprise applications in SaaS mode,
                  |Standard Subsystems Library (SSL) is required.
                  |The application you are using is missing SSL.
                  |To run the application in SaaS mode,
                  |install SSL version %1 or higher.';
                  |it = 'Nella configurazione non è inserita la biblioteca: ""1C:Biblioteca dei sottosistemi standard"".
                  |Senza l''inserimento di questa biblioteca, la configurazione non può essere utilizzata nel modello di servizio.
                  |
                  |Per utilizzare questa configurazione nel modello di servizio, è necessario implementare la biblioteca
                  |""1C:Biblioteca dei sottosistemi standard"" versione non inferiore a %1';
                  |pl = 'Do konfiguracji nie zostało wdrożono biblioteki ""1C:Biblioteka standardowych podsystemów"".
                  |Bez wdrożenia tej biblioteki konfiguracja nie może być stosowana w modelu usługi.
                  |
                  |Aby skorzystać z tej konfiguracji w modelu usług wymagane jest wprowadzenie bibliote
                  |""1C:Biblioteka standardowych podsystemów"" wersji nie niżej%1';
                  |tr = 'Yapılandırma, entegre 1C:Standard Subsystems Library içermez. 
                  |Bu kütüphane entegre değilse, yapılandırma hizmet modelinde kullanılamaz.
                  |
                  | Bu yapılandırmayı hizmet modelinde kullanmak için, 
                  | sürüm veya daha eski sürüm 1C:Standard Subsystems Library %1 entegre edilmelidir!'", Metadata.DefaultLanguage.LanguageCode),
			RequiredVersionSSL());
		
	Else
		
		SSLVersion = DetailsSSL.Version;
		
		If CommonClientServer.CompareVersions(SSLVersion, RequiredVersionSSL()) < 0 Then
			
			Raise StrTemplate(
				NStr("vi = 'Để sử dụng cấu hình trong mô hình dịch vụ với phiên bản hiện tại của thư viện
                      | ""1C: Thư viện Công nghệ Dịch vụ"", bạn cần cập nhật phiên bản đã sử dụng của
                      | ""1C: Thư viện Công nghệ Dịch vụ"".
                      |
                      |Phiên bản đã sử dụng: %1, phiên bản ít nhất %2 là bắt buộc';
                      |ru = 'Для использования конфигурации в модели сервиса с текущей версией библиотеки
                      |""1С:Библиотека технологии сервиса"" требуется обновить используемую версию
                      |библиотеки ""1С:Библиотека стандартных подсистем"".
                      |
                      |Используемая версия: %1, требуется версия не младше %2';
                      |en = 'To run the 1C:Enterprise application in the SaaS mode,
                      |you need to update the embedded SSL.
                      |
                      |The current SSL version is %1.
                      |The required SSL version is %2 or higher.'; fa = 'To run the 1C:Enterprise application in the SaaS mode,
                      |you need to update the embedded SSL.
                      |
                      |The current SSL version is %1.
                      |The required SSL version is %2 or higher.';
                      |it = 'Per utilizzare la configurazione nel modello di servizio con la versione corrente della biblioteca
                      |""1C:Biblioteca dei sottosistemi standard"", è necessario aggiornare la versione
                      | utilizzata della biblioteca ""1C:Biblioteca dei sottosistemi standard"".
                      |
                      |Versione utilizzata: %1, è richiesta la versione non inferiore a %2';
                      |pl = 'Do użytku konfiguracji w modelu usługi z bieżącą wersją biblioteki
                      |""1C:Biblioteka technologii serwisu"" chcesz zaktualizować używaną wersję
                      | biblioteki ""1C:Biblioteka standardowych podsystemów"".
                      |
                      |Używana wersja: %1, wymagana wersja nie niżej %2';
                      |tr = 'SaaS modu konfigürasyon 
                      |""1C:Service Technology Library"" kitaplığının geçerli sürümüyle kullanmak için, ""1C:Library of Standard Subsystems"" kitaplığının
                      |versiyonunu güncellemeniz gerekir.
                      |
                      |Kullanılan sürüm: %1, %2''den eski olmayan sürüm gerekli'", Metadata.DefaultLanguage.LanguageCode),
				SSLVersion, RequiredVersionSSL());
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Generates an error description for transmission via the web service
//
// Parameters:
//  ErrorInfo - ErrorInfo - information about the error
//   that you want to use for creating a description.
//
// Returns:
//  XDTODataObject - {http://www.1c.ru/SaaS/ServiceCommon }ErrorDescription
//   description of the error to be transmitted via the web service.
//
Function GetDescriptionOfWebServiceError(ErrorInfo) Export
	
	WriteLogEvent(NStr("vi = 'Thực hiện thao tác của Web-service';
						|ru = 'Выполнение операции web-сервиса';
						|en = 'Web service operation'; fa = 'Web service operation';
						|it = 'Esecuzione dell''operazione del web-service';
						|pl = 'Wykonanie operacji web-serwisu';
						|tr = 'Web servisi işlemi yürütülüyor'", Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
		DetailErrorDescription(ErrorInfo));
	
	ErrorDescription = XDTOFactory.Create(
		XDTOFactory.Type("http://www.1c.ru/SaaS/ServiceCommon", "ErrorDescription"));
		
	ErrorDescription.BriefErrorDescription = ShortErrorText(ErrorInfo);
	ErrorDescription.DetailErrorDescription = DetailedErrorText(ErrorInfo);
	
	Return ErrorDescription;
	
EndFunction

// Called before updating the information base.
// 
// Parameters: 
//  ExecuteDeferredHandlers1 - Boolean
// 
// Returns:
//  Boolean
Function BeforeUpdateInfobase(ExecuteDeferredHandlers1 = False) Export
	
	If Not Common.DataSeparationEnabled() 
		Or SaaSOperations.SeparatedDataUsageAvailable() Then
		
		Return False;
		
	EndIf;
		
	FreshExtension = Undefined;

	For Each Extension In ConfigurationExtensions.Get(New Structure("Name", "fresh"), ConfigurationExtensionsSource.Database) Do
		
		FreshExtension = Extension;
		Break;
		
	EndDo;
	
	DataFromSuppliedFreshExtension = GetCommonTemplate("fresh");
	InstallFreshExtension = False;
	
	If FreshExtension = Undefined Then
		
		InstallFreshExtension = True;
		
	Else
		
		MetadataOfSuppliedFreshExtension = New ConfigurationMetadataObject(DataFromSuppliedFreshExtension);
		MetadataOfInstalledFreshExtension = New ConfigurationMetadataObject(FreshExtension.GetData());
		
		If Not FreshExtension.Active
			Or FreshExtension.SafeMode
			Or FreshExtension.UnsafeActionProtection.UnsafeOperationWarnings
			Or FreshExtension.UseDefaultRolesForAllUsers
			Or CommonClientServer.CompareVersions(MetadataOfSuppliedFreshExtension.Version, MetadataOfInstalledFreshExtension.Version) > 0 Then
			
			FreshExtension.Delete();
			InstallFreshExtension = True;	
			
		EndIf;
		
	EndIf;
	
	If InstallFreshExtension Then
				
		FreshExtension = ConfigurationExtensions.Create();
		
		StructureOfExtensionDetails = New Structure();	
		StructureOfExtensionDetails.Insert("SafeMode", False);
		ProtectionAgainstDangerousActionsDoNotWarn = New UnsafeOperationProtectionDescription();
		ProtectionAgainstDangerousActionsDoNotWarn.UnsafeOperationWarnings = False;
		StructureOfExtensionDetails.Insert("UnsafeActionProtection", ProtectionAgainstDangerousActionsDoNotWarn);
		StructureOfExtensionDetails.Insert("UseDefaultRolesForAllUsers", False);	
		FillPropertyValues(FreshExtension, StructureOfExtensionDetails);

		FreshExtension.Write(DataFromSuppliedFreshExtension);
			
		ParametersOfUpdate = InfobaseUpdateInternal.ParametersOfUpdate();
		ParametersOfUpdate.ExecuteDeferredHandlers1 = ExecuteDeferredHandlers1;
			
		IBLock = New Structure;
		IBLock.Insert("Use", True);
		IBLock.Insert("SeamlessUpdate", False);
		IBLock.Insert("DebugMode", False);
		
		ParametersOfUpdate.IBLockSet = IBLock;
	  	
		ParametersForUpdateTask = New Array;
		ParametersForUpdateTask.Add(ParametersOfUpdate);
		
		SetExclusiveMode(True);
		
		StartDate = CurrentSessionDate();
		
		UpdateJob = CompleteTaskWithExtensions("InfobaseUpdateInternal.UpdateInfobase", ParametersForUpdateTask);
		UpdateJob = UpdateJob.WaitForExecutionCompletion();
		
		SetExclusiveMode(False);
		
		If UpdateJob.State = BackgroundJobState.Failed Then
			
			Raise DetailedErrorText(UpdateJob.ErrorInfo);
			
		ElsIf UpdateJob.State = BackgroundJobState.Canceled Then
			
			Raise NStr("vi = 'Đã hủy nhiệm vụ nền để cập nhật CSTT';
						|ru = 'Фоновое задание обновления информационной базы отменено';
						|en = 'Background job canceled: Infobase update'; fa = 'Background job canceled: Infobase update';
						|it = 'Il processo in background di aggiornamento del database è stato annullato';
						|pl = 'Zadanie aktualizacji w tle bazy informacyjnej zostało anulowane';
						|tr = 'Infobase güncelleme arka planı görevi iptal edildi'");
			
		EndIf;	
		
		EndDate = CurrentSessionDate();
		InfobaseUpdateInternal.WriteUpdateExecutionTime(StartDate, EndDate);
	
		RefreshReusableValues();
		
		Return True;
		
	EndIf;
	
	Return False;
			
EndFunction

// Run a task with extensions
// 
// Parameters:
//  JobName - String
//  Parameters - Array of Arbitrary
//  Var_Key - Undefined - Key
//  Description - String
// 
// Returns:
//  BackgroundJob
Function CompleteTaskWithExtensions(JobName, Parameters, Var_Key = Undefined, Description = Undefined) Export
	
	//@skip-warning DeprecatedMethod - a feature of the implementation.
	Return ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		JobName, Parameters, Var_Key, Description);
	
EndFunction

// Detailed error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String - Detailed error text
Function DetailedErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);

EndFunction

// The short text of the error.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String - Short error text
Function ShortErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo);

EndFunction

#EndRegion

#Region Private

// Returns the minimum supported version of the "1C" library:Library of standard subsystems".
//
// Returns:
//   String - the version of the library in the format PP.{P|PP}.ZZ.SS.
//
Function RequiredVersionSSL()

	Return "3.1.1.1";

EndFunction

#EndRegion
