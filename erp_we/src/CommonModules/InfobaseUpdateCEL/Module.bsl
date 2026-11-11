///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Information about the library (or configuration).

#Region Public

// Fills in basic information about the library or main configuration.
// A library whose name matches the name of the configuration in the metadata is defined as the main configuration.
// 
// Parameters:
//  LongDesc - Structure - information about the library:
//
//   * Name                 - String - name of the library, for example, "standard Subsystems".
//   * Version              - String - version in 4-digit format, for example, "2.1.3.1".
//
//   * RequiredSubsystems1 - Array - names of other libraries (String) that this library depends on.
//                                    Update handlers for such libraries must be called earlier
//                                    than the update handlers for this library.
//                                    If there are cyclic dependencies or, on the contrary, there are no dependencies,
//                                    the order of calling update handlers is determined by the order of adding modules
//                                    in the procedure for adding General module Subsystems
//                                    Configuration subsystems are undefined.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "ConnectedHardwareLibrary";
	LongDesc.Version = EquipmentManager.LibraryVersion();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers for updating the information base.

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - ValueTable - for a description of the fields, see the procedure.
//                Updating the information database.The new Update processing table.
//
// Example:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Execution mode = "Monopoly".
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.UpdateSuppliedDrivers";
	Handler.Comment = NStr("vi = 'Cập nhật thiết bị sẵn có của thiết bị kết nối.';
							|ru = 'Обновление поставляемых драйверов подключаемого оборудования.';
							|en = 'Update the supplied drivers of peripherals.'; fa = 'Update the supplied drivers of peripherals.';
							|it = 'Aggiornare i driver hardware forniti.';
							|pl = 'Aktualizacja dostarczanych sterowników podłączanych urządzeń.';
							|tr = 'Bağlı ekipman için yerleşik sürücülerin güncellenmesi.'");
	
	Handler = Handlers.Add();
	Handler.Version = EquipmentManager.LibraryVersion();
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.UpdateSuppliedDrivers";
	Handler.Comment = NStr("vi = 'Cập nhật thiết bị sẵn có của thiết bị kết nối.';
							|ru = 'Обновление поставляемых драйверов подключаемого оборудования.';
							|en = 'Update the supplied drivers of peripherals.'; fa = 'Update the supplied drivers of peripherals.';
							|it = 'Aggiornare i driver hardware forniti.';
							|pl = 'Aktualizacja dostarczanych sterowników podłączanych urządzeń.';
							|tr = 'Bağlı ekipman için yerleşik sürücülerin güncellenmesi.'");
	
	Handler = Handlers.Add();
	Handler.Version = EquipmentManager.LibraryVersion();
	Handler.InitialFilling = True;
	Handler.ExecutionMode =  "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.RefreshPeripherals";
	Handler.Comment = NStr("vi = 'Cập nhật thiết bị tính tiền offline.';
							|ru = 'Обновление оборудования ККМ-офлайн.';
							|en = 'Update the offline cash register equipment.'; fa = 'Update the offline cash register equipment.';
							|it = 'Aggiornamento apparecchiatura Registratore di cassa offline.';
							|pl = 'Aktualizacja urządzeń fiskalnych offline.';
							|tr = 'YK-çevrim dışı ekipmanının güncellenmesi.'");
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.UpdateLabelAndPriceTagTemplates";
	Handler.Comment = NStr("vi = 'Tạo mẫu in định trước.';
							|ru = 'Создание предопределенных шаблонов печати.';
							|en = 'Create predefined print templates.'; fa = 'Create predefined print templates.';
							|it = 'Creazione modelli di stampa predefiniti.';
							|pl = 'Utworzenie predefiniowanych szablonów drukowania.';
							|tr = 'Önceden tanımlanmış yazdırma numuneleri oluşturma.'");
	

	Handler = Handlers.Add();
	Handler.Version = "3.1.6.1";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.UpdateHardwareRegistrationParameters";
	Handler.Comment = NStr("vi = 'Bộ xử lý tham số ghi nhận thiết bị kết nối.';
							|ru = 'Обработка параметров регистрации подключаемого оборудования.';
							|en = 'Process peripheral registration parameters.'; fa = 'Process peripheral registration parameters.';
							|it = 'Обработка параметров регистрации подключаемого оборудования.';
							|pl = 'Process peripheral registration parameters.';
							|tr = 'Bağlı ekipmanın kayıt parametrelerinin işlenmesi.'"); 
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.6";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.UpdateLabelTemplates";
	Handler.Comment = NStr("vi = 'Cập nhật khuôn in nhãn tem và nhãn giá đối với định dạng mới.';
							|ru = 'Обновление макетов этикеток и ценников на новый формат.';
							|en = 'Update templates of labels and price tags to the new format.'; fa = 'Update templates of labels and price tags to the new format.';
							|it = 'Обновление макетов этикеток и ценников на новый формат.';
							|pl = 'Update templates of labels and price tags to the new format.';
							|tr = 'Şablon ve fiyat etiketlerinin yeni formata güncellenmesi.'");
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.1";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "InfobaseUpdateCEL.SetRetentionPeriodOfOperations";
	Handler.Comment = NStr("vi = 'Đặt thời hạn lưu giao dịch.';
							|ru = 'Установка срока хранения операций.';
							|en = 'Set an operation retention period.'; fa = 'Set an operation retention period.';
							|it = 'Установка срока хранения операций.';
							|pl = 'Set an operation retention period.';
							|tr = 'İşlem saklama süresi ayarlama.'");
	
	// ++ Non-mobile application
	Handler = Handlers.Add();
	Handler.Procedure = "EquipmentManager.UpdateInstalledAttachableEquipmentFromSite";
	Handler.Version = "*";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("8e0253ba-2d8f-4432-bd98-6428e2ed5dd6");
	Handler.Comment = NStr("vi = 'Cập nhật driver Thư viện thiết bị được kết nối';
							|ru = 'Обновление драйверов БПО';
							|en = 'Update PEL drivers'; fa = 'Update PEL drivers';
							|it = 'Обновление драйверов БПО';
							|pl = 'Update PEL drivers';
							|tr = 'EDK sürücülerinin güncellenmesi'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "EquipmentManager.ProcessDriversWhenUpdatingInformationBase";
	Handler.Version = "3.2.7.8";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("1446dd8a-bb1b-439b-9291-002f73c18b97");
	Handler.Comment = NStr("vi = 'Chuyển driver từ khuôn mẫu sang danh mục Cấu phần ngoài.';
							|ru = 'Перенос драйверов из макетов в справочник Внешние копоненты.';
							|en = 'Transfer drivers from templates to the ""Add-ins"" catalog.'; fa = 'Transfer drivers from templates to the ""Add-ins"" catalog.';
							|it = 'Перенос драйверов из макетов в справочник Внешние копоненты.';
							|pl = 'Transfer drivers from templates to the ""Add-ins"" catalog.';
							|tr = 'Sürücüleri düzenlerden Harici bileşenler dizinine aktarma.'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCEL.DisableUseOfScheduledJob";
	Handler.Version = "3.2.5.3";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("60b72a08-318f-47e6-bbc4-0decdf3b683a");
	Handler.Comment = NStr("vi = 'Tắt nhiệm vụ thường kỳ gửi email ở chế độ phân chia.';
							|ru = 'Отключение регламентного задания отправки электронных сообщений в разделенном режиме.';
							|en = 'Disable the scheduled job for sending email messages in separated mode.'; fa = 'Disable the scheduled job for sending email messages in separated mode.';
							|it = 'Отключение регламентного задания отправки электронных сообщений в разделенном режиме.';
							|pl = 'Disable the scheduled job for sending email messages in separated mode.';
							|tr = 'Ayrılmış modda zamanlanmış elektronik mesaj gönderimi görevinin devre dışı bırakılması.'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCEL.SetShelfLifeOfOperationsWithEquipment";
	Handler.Version = "3.2.5.4";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("cbe6ac05-81f4-4adc-a076-7c7004763a0d");
	Handler.Comment = NStr("vi = 'Đặt thời hạn lưu giao dịch với thiết bị.';
							|ru = 'Установка срока хранений операций с оборудованием.';
							|en = 'Set the retention period of operations with peripherals.'; fa = 'Set the retention period of operations with peripherals.';
							|it = 'Установка срока хранений операций с оборудованием.';
							|pl = 'Set the retention period of operations with peripherals.';
							|tr = 'Donanım işlemleri saklama süresinin ayarlanması.'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCEL.SetShelfLifeOfOperationsWithEquipment";
	Handler.Version = "3.2.6.21";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("1b6d29fd-f61b-4b55-9540-227fe1dea0d3");
	Handler.Comment = NStr("vi = 'Đặt thời hạn lưu giao dịch với thiết bị.';
							|ru = 'Установка срока хранений операций с оборудованием.';
							|en = 'Set the retention period of operations with peripherals.'; fa = 'Set the retention period of operations with peripherals.';
							|it = 'Установка срока хранений операций с оборудованием.';
							|pl = 'Set the retention period of operations with peripherals.';
							|tr = 'Donanım işlemleri saklama süresinin ayarlanması.'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCEL.SetShelfLifeOfOperationsWithEquipment";
	Handler.Version = "3.2.7.6";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("ce880442-c73f-4961-b6a2-4817ede7948e");
	Handler.Comment = NStr("vi = 'Đặt thời hạn lưu giao dịch với thiết bị.';
							|ru = 'Установка срока хранений операций с оборудованием.';
							|en = 'Set the retention period of operations with peripherals.'; fa = 'Set the retention period of operations with peripherals.';
							|it = 'Установка срока хранений операций с оборудованием.';
							|pl = 'Set the retention period of operations with peripherals.';
							|tr = 'Donanım işlemleri saklama süresinin ayarlanması.'");
	
	Handler = Handlers.Add();
	Handler.Procedure = "InfobaseUpdateCEL.InstallVersionOfExchangeFormatKKMED";
	Handler.Version = "3.2.9.6";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("295e22e4-9d3f-4915-b592-46a33dfc4f22");
	Handler.Comment = NStr("vi = 'Thiết lập phiên bản định dạng trao đổi trên một thiết bị ngoại tuyến.';
							|ru = 'Установка версии формата обмена в экземпляре Офлайн-оборудования.';
							|en = 'Install the exchange format version in an Offline peripherals instance.'; fa = 'Install the exchange format version in an Offline peripherals instance.';
							|it = 'Install the exchange format version in an Offline peripherals instance.';
							|pl = 'Install the exchange format version in an Offline peripherals instance.';
							|tr = 'Çevrimdışı donanım örneğinde değişim formatı sürümü ayarı.'");
    
	// -- Non-mobile application
	
EndProcedure

// Called before procedures that handle updating is data.
//
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// Called after the is data update is complete.
// 
// Parameters:
//   PreviousVersion       - String - version before update. "0.0.0.0" for "empty" is.
//   CurrentVersion          - String - version after the update.
//   CompletedHandlers - ValueTree - a list of completed update handler procedures,
//                                             grouped by version number.
//   OutputUpdatesDetails - Boolean - if set to True, a form
//                                with a description of updates will be displayed. By default, True.
//                                Returned value.
//   ExclusiveMode           - Boolean - True if the update was performed in exclusive mode.
//
// Example:
//  Example of bypassing executed update handlers:
//	For Each Version Of The Executed processors.Lines Cycle
//		
//		If The Version.Version = "*" Then
//			A handler that can be executed every time the version is changed.
//		Otherwise
//			A handler that is executed for a specific version.
//		The end if;
//		
//		For Each Handler From The Version.The lines are a Cycle
//			...
//		the end of the cycle;
//		
//	The end of the cycle;
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	
EndProcedure

// Called when preparing a table document describing changes in the program.
//
// Parameters:
//   Template - SpreadsheetDocument - description of updating all libraries and configurations.
//           The Template can be supplemented or replaced.
//            See also the general Template for the description of system changes.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Allows you to override the data update mode of the information database.
// For use in rare (non-standard) cases of transition that are not provided for in
// the standard procedure for determining the update mode.
//
// Parameters:
//   DataUpdateMode - String - in the handler, you can assign one of the values:
//              "Initial filling" - if this is the first launch of an empty database (data area);
//              "Version update" - if the first launch is performed after updating the database configuration;
//              "Transition to another program" - if the first run is performed after updating the database configuration 
//                                          in which the name of the main configuration has changed.
//
//   StandardProcessing  - Boolean - if set to False, the standard procedure
//                                    for determining the update mode is not performed, 
//                                    but the value of the data update Mode is used.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
 
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable - with columns:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//                                           or " * " if you want to perform it when switching from any configuration.
//    * Procedure                 - String - the full name of the procedure that handles the transition from the program to the previous configuration name. 
//                                  For example, "Updating the information database".Fill out the accounting policy"
//                                  It must be exported.
//
// Example:
//  Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out the accounting policy."
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
 
EndProcedure

// Called after all transition handler procedures have been executed from another program (with a different configuration name),
// and before the start of updating the is data.
//
// Parameters:
//  PreviousConfigurationName    - String - name of the configuration before the transition.
//  PreviousConfigurationVersion - String - name of the previous configuration (before the transition).
//  Parameters                    - Structure:
//    * ExecuteUpdateFromVersion   - Boolean - by default, True. If set to False, 
//        only the required update handlers (with the "* " version) will be executed.
//    * ConfigurationVersion           - String - version number after the transition. 
//        By default, it is equal to the value of the configuration version in the metadata properties.
//        To run, for example, all update handlers from the previous configuration Version, 
//        set the parameter value to previous configuration Version.
//        To run all update handlers at all, set the value to "0.0.0.1".
//    * ClearPreviousConfigurationInfo - Boolean - the default is True. 
//        For cases when the previous configuration matches the name of the Cur configuration subsystem, you should specify False.
//
Procedure OnCompleteApplicationMigration(Val PreviousConfigurationName, Val PreviousConfigurationVersion, Parameters) Export
 
EndProcedure

#EndRegion

#Region Internal

#Region UpdateProcedures
// APK:1327-off procedures are performed in exclusive mode, #STD490 n 2.
// APK:1328-off procedures are performed in exclusive mode, #STD490 n 2.

// To update the supplied driver to the PCM.
//
Procedure UpdateSuppliedDrivers(Parameters = Undefined) Export
	
	EquipmentManager.UpdateSuppliedDrivers();
	EquipmentManager.UpdateInstalledDrivers();
	
EndProcedure

// Upgrade the equipment.
//
Procedure RefreshPeripherals(Parameters = Undefined) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Peripherals.Ref AS Ref,
		|	Peripherals.EquipmentType AS EquipmentType
		|FROM
		|	Catalog.Peripherals AS Peripherals";
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	ErrorTextTemplate = NStr("vi = 'Không thể xử lý cập nhật thiết bị kết nối do nguyên nhân: %1';
							|ru = 'Не удалось обработать обновление подключаемого оборудования по причине: %1';
							|en = 'Cannot process the peripherals update due to: %1'; fa = 'Cannot process the peripherals update due to: %1';
							|it = 'Non è stato possibile elaborare l''aggiornamento dell''apparecchiatura connessa a causa di: %1';
							|pl = 'Nie udało się przetworzyć aktualizacji podłączanych urządzeń z powodu: %1';
							|tr = 'Bağlanan ekipman güncellemesi bu nedenle işlenemedi: %1'", CommonCEL.DefaultLanguageCode());
	
	While Selection.Next() Do
		BeginTransaction();
		Try
			ToProcessPeripherals(Selection.Ref);
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorText = StrTemplate(ErrorTextTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Cập nhật cơ sở thông tin';
					|ru = 'Обновление информационной базы';
					|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
					|it = 'Aggiornamento del database';
					|pl = 'Aktualizacja bazy informacyjnej';
					|tr = 'Infobase güncellemesi'", CommonCEL.DefaultLanguageCode()),
				ErrorText);
		EndTry;
	EndDo;
	
	If CommonCEL.OfflineEquipmentIsUsed() Then
		OfflineHardwareManagerModuleServerCallRedefinable = CommonCEL.CommonModule("OfflineEquipmentManagerServerCallOverridable");
		OfflineHardwareManagerModuleServerCallRedefinable.AdditionalProcessingOfObjectsWhenSwitchingToOfflineEquipment();
	EndIf;
	
EndProcedure

// Update the templates of BPO labels and price tags.
//
Procedure UpdateLabelAndPriceTagTemplates(Parameters = Undefined) Export    
	                                          
	If CommonCEL.PrintingOfLabelsAndPriceTagsIsUsed() Then
		ModulePrintingOfBPOLabelsAndPriceTags = CommonCEL.CommonModule("PrintPLLabelsAndPriceTags");
		ModulePrintingOfBPOLabelsAndPriceTags.FillInPredefinedElements();
	EndIf;
	
EndProcedure

// APK:1328-on
// APK:1327-on

// update Cash register registration parameters
//
Procedure UpdateHardwareRegistrationParameters(Parameters = Undefined) Export    
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	PeripheralsRegistrationParameters.Ref AS Ref
		|FROM
		|	Catalog.Peripherals.RegistrationParameters AS PeripheralsRegistrationParameters
		|WHERE
		|	PeripheralsRegistrationParameters.ParameterValue IN (&PossibleValues)
		|
		|GROUP BY
		|	PeripheralsRegistrationParameters.Ref";
	PossibleValues = New Array(4);
	PossibleValues.Add("Yes");
	PossibleValues.Add("None");
	PossibleValues.Add("Yes");
	PossibleValues.Add("No");
	Query.SetParameter("PossibleValues", PossibleValues);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock();
		LockItem = Block.Add("Catalog.Peripherals");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = Result;
		LockItem.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			Object = Selection.Ref.GetObject();
			For Each String In Object.RegistrationParameters Do
				If String.ParameterValue = "Yes"
					Or String.ParameterValue = "Yes" Then
					String.ParameterValue = XMLString(True);
				ElsIf String.ParameterValue = "None"
					Or String.ParameterValue = "No" Then
					String.ParameterValue = XMLString(False);
				EndIf;
			EndDo;
			Object.Write();
			
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorTextTemplate = NStr("vi = 'Không thể chuyển tham số ghi nhận thiết bị kết nối theo nguyên nhân:
			|%1';
			|ru = 'Не удалось преобразовать параметры регистрации подключаемого оборудования по причине:
			|%1';
			|en = 'Cannot convert the peripheral registration parameters. Reason:
			|%1'; fa = 'Cannot convert the peripheral registration parameters. Reason:
			|%1';
			|it = 'Не удалось преобразовать параметры регистрации подключаемого оборудования по причине:
			|%1';
			|pl = 'Cannot convert the peripheral registration parameters. Reason:
			|%1';
			|tr = 'Bağlanan ekipman kayıt parametreleri bu nedenle dönüştürülemedi:
			|%1'", CommonCEL.DefaultLanguageCode());
		ErrorText = StrTemplate(ErrorTextTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Cập nhật cơ sở thông tin';
				|ru = 'Обновление информационной базы';
				|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
				|it = 'Aggiornamento del database';
				|pl = 'Aktualizacja bazy informacyjnej';
				|tr = 'Infobase güncellemesi'", CommonCEL.DefaultLanguageCode()),
			ErrorText);
	EndTry;
	
		
EndProcedure

// update the label Templates to the new format.
//
Procedure UpdateLabelTemplates(Parameters = Undefined) Export 
	
	If CommonCEL.PrintingOfLabelsAndPriceTagsIsUsed() Then
		ModulePrintingOfBPOLabelsAndPriceTags = CommonCEL.CommonModule("PrintPLLabelsAndPriceTags");
		ModulePrintingOfBPOLabelsAndPriceTags.UpdateLabelTemplates(Parameters);
	EndIf;
	
EndProcedure

// Set the value of constants for the retention periods of operations in the information registers
//
Procedure SetRetentionPeriodOfOperations(Parameters = Undefined) Export 
	
	// ++ Non-mobile application
	If CommonCEL.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");
		ModuleEquipmentPaymentSystems.SetRetentionPeriodOfOperations();
	EndIf;
		
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		ModuleEquipmentReceiptPrintingDevices.SetRetentionPeriodForFiscalTransactions();
		If CommonCEL.DistributedFiscalizationIsUsed() Then
			ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
			ModuleDistributedFiscalization.SetRetentionPeriodForOperationsInReceiptQueue();
		EndIf;
	EndIf;
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		ModuleEquipmentManagerMarking.SetRetentionPeriodForCRVerificationOperations();
	EndIf;
	
	SetShelfLifeOfOperationsWithEquipment(Parameters);
	
	// -- Non-mobile application
	
EndProcedure

// ++ Non-mobile application

Procedure SetShelfLifeOfOperationsWithEquipment(Parameters = Undefined) Export

	If CommonCEL.LoggingSubsystemIsUsed() Then
		ModuleLoggingOfOperationsOfBPO = CommonCEL.CommonModule("LoggingOfCELOperations");
		ModuleLoggingOfOperationsOfBPO.SetShelfLifeOfOperationsWithEquipment();
	EndIf;
	
EndProcedure

// Disables the routine task of Sending electronic checks in split mode, activation will occur when an
// electronic check is generated for sending by means of 1C
Procedure DisableUseOfScheduledJob(Parameters = Undefined) Export
	
	If CommonCEL.ElectronicCashReceiptMailoutIsUsed() Then
		ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
		ElectronicReceiptMailingModule.DisableUseOfScheduledJob();
	EndIf;
	
EndProcedure

Procedure InstallVersionOfExchangeFormatKKMED(Parameters = Undefined) Export
	
	If CommonCEL.OfflineEquipmentIsUsed() Then
		OfflineEquipmentManagerModule = CommonCEL.CommonModule("OfflineEquipmentManager");
		OfflineEquipmentManagerModule.InstallVersionOfExchangeFormatKKMED(Parameters);
	EndIf;
	
EndProcedure

// -- Non-mobile application

#EndRegion

#Region AllowedMethodsToBeCalledAsArbitraryCode

// Returns a list of methods that can be called as arbitrary code
// (for routine tasks and background tasks)
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateHardwareRegistrationParameters", True);
	Methods.Insert("DisableUseOfScheduledJob", True);
	Methods.Insert("UpdateLabelTemplates", True);
	Methods.Insert("CreateContactInformationKinds", True);
	Methods.Insert("UpdateLabelAndPriceTagTemplates", True);
	Methods.Insert("RefreshPeripherals", True);
	Methods.Insert("UpdateSuppliedDrivers", True);
	Methods.Insert("SetShelfLifeOfOperationsWithEquipment", True);
	Methods.Insert("SetRetentionPeriodOfOperations", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// APK:1327-off procedures are performed in exclusive mode, #STD490 n 2.
// APK:1328-off procedures are performed in exclusive mode, #STD490 n 2.

// Performs additional equipment processing
//
// Parameters:
//  LinkToEquipment - CatalogRef.Peripherals
//
Procedure ToProcessPeripherals(LinkToEquipment)
	
	EquipmentManagerServerCallOverridable.UpdateCatalogOfConnectedEquipment(LinkToEquipment);
	
EndProcedure

// APK:1328-on
// APK:1327-on

#EndRegion
