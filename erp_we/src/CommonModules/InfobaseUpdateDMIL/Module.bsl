////////////////////////////////////////////////////////////////////////////////
// Updating the information base of the Integration Library with 1C:Document management
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Information about the library (or configuration).

// Fills in basic information about the library or main configuration.
// A library whose name matches the name of the configuration in the metadata is defined as the main configuration.
//
// Parameters:
//   LongDesc - Structure:
//
//     * Name                 - String - name of the library, for example, "standard Subsystems".
//     * Version              - String - version in 4-digit format, for example, "2.1.3.1".
//
//     * OnlineSupportID - String - unique name of the program in Internet support services.
//     * RequiredSubsystems1 - Array of String - names of other libraries that this library depends on.
//                                      The update handlers of such libraries must be called earlier
//                                      than the update handlers of this library.
//                                      In case of cyclic dependencies or, on the contrary, the absence of any dependencies,
//                                      the order of calling update handlers is determined by the order of adding modules
//                                      in the procedure for adding subsystems of a common module
//                                      The configuration subsystems are undefined.
//     * DeferredHandlersExecutionMode - String - "Sequentially" - deferred update handlers are executed
//                                      sequentially in the range from the version number of the information database to
//                                      the configuration version number inclusive, or "in Parallel" - the deferred
//                                      handler passes control to the next handler after processing the first batch of data, and after
//                                      the last handler is executed, the cycle repeats again.
//     * FillDataNewSubsystemsWhenSwitchingFromAnotherProgram - Boolean - If the Truth is set, then when switching from
//                                      another program, handlers for the initial filling
//                                      of new subsystems will be automatically executed. When describing the update handler, you can, if necessary
//                                      , disable its execution by specifying the Non-Pass property of another program.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name = "DocumentManagementIntegrationLibrary";
	LongDesc.Version = "3.0.4.2";
	LongDesc.OnlineSupportID = "DMIL";
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	LongDesc.DeferredHandlersExecutionMode = "Sequentially";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Handlers for updating the information base.

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//   Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example:
//	Handler = Handlers.Add();
//	Handler.Version = "1.1.0.0";
//	Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//	Handler.Execution Mode = "Monopoly";
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Handlers that are executed every time the information security is updated.
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "InfobaseUpdateDMIL.FillSeparatedDataHandlers";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "InfobaseUpdateDMIL.CheckIfIntegrationRulesMatchMetadata";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Kiểm tra quy tắc tích hợp với 1C:Document Management';
							|ru = 'Проверка правил интеграции с 1С:Документооборотом';
							|en = 'Check integration rules with 1C:Document Management'; fa = 'Check integration rules with 1C:Document Management';
							|it = 'Verifica delle regole di integrazione con 1C:Document Management';
							|pl = 'Sprawdzenie reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı kontrolü'");
	
	// The Information Database update handler should not work out in the service mode,
	// so its registration is missing in the Fill in the processing method of the separated data.
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "InfobaseUpdateDMIL.WhenUpdatingInformationBase";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Kiểm tra sự tương ứng giữa các kiểu xác định và sơ đồ trao đổi';
							|ru = 'Проверка соответствия определяемых типов и плана обмена';
							|en = 'Verification of correspondence of defined types and exchange plan'; fa = 'Verification of correspondence of defined types and exchange plan';
							|it = 'Verifica di corrispondenza di tipi definibili e del piano di scambio';
							|pl = 'Sprawdzenie zgodności określanych typów i planu wymiany';
							|tr = 'Tanımlanan türlerin ve değişim planının uygunluğunun kontrolü'");
	
	// Handlers that are executed when switching to a specific version.
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.6.1";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_1_1_6_1";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.8.4";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_1_1_8_4";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với ""1C:Document Management""';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом""';
							|en = 'Update integration rules with 1C:Document Management'; fa = 'Update integration rules with 1C:Document Management';
							|it = 'Обновление правил интеграции с 1С:Документооборотом""';
							|pl = 'Update integration rules with 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "1.1.12.2";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_1_1_12_2";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.1";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_3_0_1_1";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.1";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_3_0_2_1";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.5";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_3_0_2_5";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.3.1";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_3_0_3_1";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = StrTemplate(
		NStr("vi = 'Chuyển cài đặt sang nhiệm vụ thường kỳ mới ""%1"", được điều chỉnh để làm việc trong chế độ dịch vụ về công nghệ 1C:Fresh';
			|ru = 'Перенос настроек в новое регламентное задание ""%1"", адаптированное для работы в режиме сервиса по технологии 1С:Фреш';
			|en = 'Transfer settings to the new ""%1"" scheduled job adapted for SaaS mode using 1C:Fresh technology'; fa = 'Transfer settings to the new ""%1"" scheduled job adapted for SaaS mode using 1C:Fresh technology';
			|it = 'Перенос настроек в новое регламентное задание ""%1"", адаптированное для работы в режиме сервиса по технологии 1С:Фреш';
			|pl = 'Transfer settings to the new ""%1"" scheduled job adapted for SaaS mode using 1C:Fresh technology';
			|tr = 'Ayarların 1C:Fresh teknolojisi kullanılarak servis modunda çalışmaya uyarlanmış yeni ""%1"" zamanlanmış görevinin aktarımı'"),
		Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement.Synonym);
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.4.2";
	Handler.Procedure = "InfobaseUpdateDMIL.RestoreVersion_3_0_4_2";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("vi = 'Cập nhật quy tắc tích hợp với 1C:Document Management';
							|ru = 'Обновление правил интеграции с 1С:Документооборотом';
							|en = 'Integration rules updating with 1C:Document Management'; fa = 'Integration rules updating with 1C:Document Management';
							|it = 'Aggiornamento delle regole di integrazione con 1C:Document Management';
							|pl = 'Aktualizacja reguł integracji z 1C:Document Management';
							|tr = '1C:Document Management ile entegrasyon kuralı güncelleme'");
	
EndProcedure

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("FillSeparatedDataHandlers");
	Methods.Insert("CheckIfIntegrationRulesMatchMetadata");
	Methods.Insert("WhenUpdatingInformationBase");
	Methods.Insert("RestoreVersion_1_1_6_1");
	Methods.Insert("RestoreVersion_1_1_8_4");
	Methods.Insert("RestoreVersion_1_1_12_2");
	Methods.Insert("RestoreVersion_3_0_1_1");
	Methods.Insert("RestoreVersion_3_0_2_1");
	Methods.Insert("RestoreVersion_3_0_2_5");
	Methods.Insert("RestoreVersion_3_0_3_1");
	Methods.Insert("RestoreVersion_3_0_4_2");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Utility methods.

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
//	For Each Version Of The Executed processors.Lines Cycle
//		
//		If The Version.Version = "*" Then
//			A handler that can be executed every time the version is changed.
//		Otherwise
//			A handler that is executed for a specific version.
//		The end if;
//		
//		For Each Handler From The Version.The lines of the Cycle
//			...
//		the end of the cycle;
//		
//	The end of the cycle;
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	
	
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable:
//    * PreviousConfigurationName - String - name of the configuration to be migrated from;
//                                           or " * " if you want to perform it when switching from any configuration.
//    * Procedure                 - String - full name of the transition handler procedure from the program
//                                           Premiumecigarette.
//                                  For Example, " Updating The Information Base Of The PPI.Fill in the accounting policy"
//                                  It must be exported.
//
// Example:
//  Handler = Handlers.Add();
//  Handler.Previous Configuration Name = "Trade Management";
//  Handler.Procedure = "Updating the information database.Fill out Accounting policy";
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
//    * ClearPreviousConfigurationInfo - Boolean - by default, True.
//        If the previous configuration matches the name of the subsystem in the current configuration,
//        specify False.
//
Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters) Export
	
	
	
EndProcedure

// Called when determining the data update mode.
//
// Parameters:
//   DataUpdateMode - String - update mode.
//   StandardProcessing - Boolean - False if you need to change the default mode.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
	
	
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

#EndRegion

#Region Private

// Fills in the split data handler that depends on changes to the undivided data.
//
// Parameters:
//   Parameters - Structure - structure of handler parameters:
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "InfobaseUpdateDMIL.CheckIfIntegrationRulesMatchMetadata";
		Handler.ExecutionMode = "Seamless";
		Handler.Comment = NStr("vi = 'Kiểm tra quy tắc tích hợp với 1C:Document Management';
								|ru = 'Проверка правил интеграции с 1С:Документооборотом';
								|en = 'Check integration rules with 1C:Document Management'; fa = 'Check integration rules with 1C:Document Management';
								|it = 'Verifica delle regole di integrazione con 1C:Document Management';
								|pl = 'Sprawdzenie reguł integracji z 1C:Document Management';
								|tr = '1C:Document Management ile entegrasyon kuralı kontrolü'");
	EndIf;
	
EndProcedure

// A handler that checks whether the integration rules match the configuration metadata.
//
Procedure CheckIfIntegrationRulesMatchMetadata() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.CheckIfIntegrationRulesMatchMetadata();
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo3() Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ModuleIntegrationWith1CDocumentManagement3.CheckIfIntegrationRulesMatchMetadata();
	EndIf;
	
EndProcedure

// Called when updating the IB.
//
Procedure WhenUpdatingInformationBase() Export
	
	Errors = New Array;
	
	CheckCorrespondenceOfDefinedTypesWithEachOther(Errors);
	VerifyComplianceOfDefinedTypesAndExchangePlan(Errors);
	
	If Errors.Count() = 0 Then
		Return;
	EndIf;
	
	ErrorsText = StrConcat(Errors, Chars.LF);
	Raise ErrorsText;
	
EndProcedure

// Checks the composition of the defined types against each other, causing exceptions.
//
// Parameters:
//   Errors - Array of String
//
Procedure CheckCorrespondenceOfDefinedTypesWithEachOther(Errors) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.CheckCorrespondenceOfDefinedTypesWithEachOther(
		Errors,
		StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	NameOfAllLinksType =
		Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Presentation();
	NameOfDocumentsObjectsType =
		Metadata.DefinedTypes.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable.Presentation();
	NameOfObjectCatalogType =
		Metadata.DefinedTypes.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable.Presentation();
	
	TypesOfObjectsThatSupportIntegration =
		IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	For Each ValueType In TypesOfObjectsThatSupportIntegration Do
		
		MetadataObject = Metadata.FindByType(ValueType);
		
		If MetadataObject = Undefined
				Or Not IntegrationWith1CDocumentManagementCore.MetadataObjectIsSupported(MetadataObject) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã chọn trong kiểu nhất định ""%2"", nhưng không hỗ trợ tích hợp đối tượng này với DM.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но интеграция данного объекта с ДО не поддерживается.';
						|en = 'Type ""%1"" is selected in the defined type ""%2"", but the integration of this object with DI is not supported.'; fa = 'Type ""%1"" is selected in the defined type ""%2"", but the integration of this object with DI is not supported.';
						|it = 'Tipo ""%1"" selezionato nel tipo definibile ""%2"", ma l''integrazione di questo oggetto con DM non è supportata.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale integracja tego obiektu z DM nie jest obsługiwana.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak bu nesnenin İş Akışı ile entegrasyonu desteklenmiyor.'"),
					ValueType,
					NameOfAllLinksType));
			Continue;
		EndIf;
		
		If Not Common.IsReference(ValueType) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng trong đó chỉ được đưa vào các kiểu tham chiếu.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но в него должны быть включены только ссылочные типы.';
						|en = 'The type ""%1"" is selected in the defined type ""%2"", but only reference types should be enabled in it.'; fa = 'The type ""%1"" is selected in the defined type ""%2"", but only reference types should be enabled in it.';
						|it = 'Tipo ""%1"" selezionato nel tipo definibile ""%2"", ma in esso devono essere inclusi solo i tipi di riferimento.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale do niego powinny być włączone tylko referencyjne typy.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak içinde yalnızca bağlantı türleri yer almalıdır.'"),
					ValueType,
					NameOfAllLinksType));
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		
		If Common.IsDocument(MetadataObject) Then
			TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(FullName, False);
			If Not Metadata.DefinedTypes.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable.Type.ContainsType(Type(TypeName)) Then
				Errors.Add(StrTemplate(
					NStr("vi = 'Chứng từ ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng không có trong kiểu ""%3"".';
						|ru = 'Документ ""%1"" выбран в определяемом типе ""%2"", но отсутствует в типе ""%3"".';
						|en = 'The ""%1"" document is selected in the ""%2"" flexible type collection but is not present in the ""%3"" type.'; fa = 'The ""%1"" document is selected in the ""%2"" flexible type collection but is not present in the ""%3"" type.';
						|it = 'Documento ""%1"" selezionato nel tipo definibile ""%2"", ma è assente nel tipo ""%3"".';
						|pl = 'Dokument ""%1"" jest wybrany w określonym typie ""%2"", ale nie ma go w typie ""%3"".';
						|tr = '""%1"" begesi tanımlanan ""%2"" türde seçildi, ancak ""%3"" türde mevcut değil.'"),
					MetadataObject.Name,
					NameOfAllLinksType,
					NameOfDocumentsObjectsType));
			EndIf;
		Else
			TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(FullName, False);
			If Not Metadata.DefinedTypes.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable.Type.ContainsType(Type(TypeName)) Then
				Errors.Add(StrTemplate(
					NStr("vi = 'Chứng từ ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng không có trong kiểu ""%3"".';
						|ru = 'Справочник ""%1"" выбран в определяемом типе ""%2"", но отсутствует в типе ""%3"".';
						|en = 'The ""%1"" catalog is selected in the ""%2"" flexible type collection but is missing in the ""%3"" type.'; fa = 'The ""%1"" catalog is selected in the ""%2"" flexible type collection but is missing in the ""%3"" type.';
						|it = 'La directory ""%1"" è selezionata nel tipo definibile ""%2"", ma è assente nel tipo ""%3"".';
						|pl = 'Katalog ""%1"" jest wybrany w określonym typie ""%2"", ale nie ma go w typie ""%3"".';
						|tr = '""%1"" kataloğu tanımlanan ""%2"" türde seçildi, ancak ""%3"" türünde mevcut değil.'"),
					MetadataObject.Name,
					NameOfAllLinksType,
					NameOfObjectCatalogType));
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each ValueType In Metadata.DefinedTypes.IntegrationWith1CDocumentManagementDocumentsObjectsOverridable.Type.Types() Do
		
		MetadataObject = Metadata.FindByType(ValueType);
		
		If MetadataObject = Undefined Or Not Common.IsDocument(MetadataObject) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng trong đó chỉ được đưa vào các chứng từ.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но в него должны быть включены только документы.';
						|en = 'Type ""%1"" is selected in the defined type ""%2"", but it should only enable documents.'; fa = 'Type ""%1"" is selected in the defined type ""%2"", but it should only enable documents.';
						|it = 'Tipo ""%1"" selezionato nel tipo definibile ""%2"", ma in esso devono essere inclusi solo documenti.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale do niego powinny być włączone tylko dokumenty.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak buna yalnızca belgeler dahil edilmelidir.'"),
					ValueType,
					NameOfDocumentsObjectsType));
			Continue;
		EndIf;
		
		If Common.IsReference(ValueType) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng trong đó chỉ được đưa vào các kiểu %3.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но в него должны быть включены только типы %3.';
						|en = 'The ""%1"" type is selected in the ""%2"" flexible type collection but it should include only %3 types.'; fa = 'The ""%1"" type is selected in the ""%2"" flexible type collection but it should include only %3 types.';
						|it = 'Il tipo ""%1"" è selezionato nel tipo definibile ""%2"", ma in esso devono essere incluse solo i tipi %3.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale do niego powinny być włączone tylko %3.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak buna sadece %3 türleri dahil edilmelidir.'"),
					ValueType,
					NameOfDocumentsObjectsType,
					"DocumentObject"));
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		
		TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(FullName);
		If Not Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.ContainsType(Type(TypeName)) Then
			Errors.Add(StrTemplate(
				NStr("vi = 'Chứng từ ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng không có trong kiểu ""%3"".';
					|ru = 'Документ ""%1"" выбран в определяемом типе ""%2"", но отсутствует в типе ""%3"".';
					|en = 'The ""%1"" document is selected in the ""%2"" flexible type collection but is not present in the ""%3"" type.'; fa = 'The ""%1"" document is selected in the ""%2"" flexible type collection but is not present in the ""%3"" type.';
					|it = 'Documento ""%1"" selezionato nel tipo definibile ""%2"", ma è assente nel tipo ""%3"".';
					|pl = 'Dokument ""%1"" jest wybrany w określonym typie ""%2"", ale nie ma go w typie ""%3"".';
					|tr = '""%1"" begesi tanımlanan ""%2"" türde seçildi, ancak ""%3"" türde mevcut değil.'"),
				MetadataObject.Name,
				NameOfDocumentsObjectsType,
				NameOfAllLinksType));
		EndIf;
		
	EndDo;
	
	For Each ValueType In Metadata.DefinedTypes.IntegrationWith1CDocumentManagementCatalogsObjectsOverridable.Type.Types() Do
		
		MetadataObject = Metadata.FindByType(ValueType);
		
		If MetadataObject = Undefined Or Common.IsDocument(MetadataObject) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng trong đó chỉ được đưa vào các danh mục.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но в него должны быть включены только справочники.';
						|en = 'Type ""%1"" is selected in the defined type ""%2"", but it should only enable directories.'; fa = 'Type ""%1"" is selected in the defined type ""%2"", but it should only enable directories.';
						|it = 'Il tipo ""%1"" è selezionato nel tipo definibile ""%2"", ma in esso devono essere incluse solo le directory.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale do niego powinny być włączone tylko katalogi.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak buna yalnızca kataloglar dahil edilmelidir.'"),
					ValueType,
					NameOfObjectCatalogType));
			Continue;
		EndIf;
		
		If Common.IsReference(ValueType) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Kiểu ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng trong đó chỉ được đưa vào các kiểu %3.';
						|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но в него должны быть включены только типы %3.';
						|en = 'The ""%1"" type is selected in the ""%2"" flexible type collection but it should include only %3 types.'; fa = 'The ""%1"" type is selected in the ""%2"" flexible type collection but it should include only %3 types.';
						|it = 'Il tipo ""%1"" è selezionato nel tipo definibile ""%2"", ma in esso devono essere incluse solo i tipi %3.';
						|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale do niego powinny być włączone tylko %3.';
						|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak buna sadece %3 türleri dahil edilmelidir.'"),
					ValueType,
					NameOfObjectCatalogType,
					"CatalogObject"));
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		
		TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(FullName);
		If Not Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.ContainsType(Type(TypeName)) Then
			Errors.Add(StrTemplate(
				NStr("vi = 'Chứng từ ""%1"" đã được chọn trong kiểu nhất định ""%2"", nhưng không có trong kiểu ""%3"".';
					|ru = 'Справочник ""%1"" выбран в определяемом типе ""%2"", но отсутствует в типе ""%3"".';
					|en = 'The ""%1"" catalog is selected in the ""%2"" flexible type collection but is missing in the ""%3"" type.'; fa = 'The ""%1"" catalog is selected in the ""%2"" flexible type collection but is missing in the ""%3"" type.';
					|it = 'La directory ""%1"" è selezionata nel tipo definibile ""%2"", ma è assente nel tipo ""%3"".';
					|pl = 'Katalog ""%1"" jest wybrany w określonym typie ""%2"", ale nie ma go w typie ""%3"".';
					|tr = '""%1"" kataloğu tanımlanan ""%2"" türde seçildi, ancak ""%3"" türünde mevcut değil.'"),
				MetadataObject.Name,
				NameOfObjectCatalogType,
				NameOfAllLinksType));
		EndIf;
		
	EndDo;
	
EndProcedure

// Checks the defined types against the exchange plan, causing exceptions.
//
// Parameters:
//   Errors - Array of String
//
Procedure VerifyComplianceOfDefinedTypesAndExchangePlan(Errors) Export
	
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.VerifyComplianceOfDefinedTypesAndExchangePlan(
		Errors,
		StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	NameOfAllLinksType =
		Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Presentation();
	NameOfExchangePlanType =
		Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Presentation();
	
	For Each CompositionItem In Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Content Do
		
		MetadataObject = CompositionItem.Metadata;
		FullName = MetadataObject.FullName();
		
		If Not IntegrationWith1CDocumentManagementCore.MetadataObjectIsSupported(MetadataObject) Then
			Errors.Add(StrTemplate(
					NStr("vi = 'Đối tượng ""%1"" có trong sơ đồ trao đổi ""%2"", nhưng không hỗ trợ tích hợp đối tượng này với DM.';
						|ru = 'Объект ""%1"" есть в плане обмена ""%2"", но интеграция данного объекта с ДО не поддерживается.';
						|en = 'The ""%1"" object is available in the ""%2"" exchange plan but its integration with EDI is not supported.'; fa = 'The ""%1"" object is available in the ""%2"" exchange plan but its integration with EDI is not supported.';
						|it = 'L''oggetto ""%1"" è nel piano di scambio ""%2"", ma l''integrazione di questo oggetto non è supportata in DM.';
						|pl = 'Obiekt ""%1"" jest w planie wymiany ""%2"", ale integracja tego obiektu z Document Management nie jest obsługiwana.';
						|tr = '""%1"" nesnesi ""%2"" değişim planında mevcut, ancak bu nesnenin İş Akışı ile entegrasyonu desteklenmiyor.'"),
					FullName,
					NameOfExchangePlanType));
			Continue;
		EndIf;
		
		TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(FullName);
		If Not Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.ContainsType(Type(TypeName)) Then
			Errors.Add(StrTemplate(
				NStr("vi = 'Đối tượng ""%1"" có trong sơ đồ trao đổi ""%2"", nhưng không có trong kiểu ""%3"".';
					|ru = 'Объект ""%1"" есть в плане обмена ""%2"", но отсутствует в типе ""%3"".';
					|en = 'The ""%1"" object is in the ""%2"" exchange plan but is missing in the ""%3"" type.'; fa = 'The ""%1"" object is in the ""%2"" exchange plan but is missing in the ""%3"" type.';
					|it = 'L''oggetto ""%1"" è nel piano di scambio ""%2"", ma manca nel tipo ""%3"".';
					|pl = 'Obiekt ""%1"" jest w planie wymiany ""%2"", ale nie ma go w typie ""%3"".';
					|tr = '""%1"" nesnesi ""%2"" değişim planında mevcut, ancak ""%3"" türünde mevcut değil.'"),
				FullName,
				NameOfExchangePlanType,
				NameOfAllLinksType));
		EndIf;
		
	EndDo;
	
	TypesOfObjectsThatSupportIntegration =
		IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	For Each ValueType In TypesOfObjectsThatSupportIntegration Do
		
		MetadataObject = Metadata.FindByType(ValueType);
		
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		If Not Metadata.ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.Content.Contains(MetadataObject) Then
			Errors.Add(StrTemplate(
				NStr("vi = 'Kiểu ""%1"" đã được chọn vào kiểu nhất định ""%2"", nhưng không có trong thành phần sơ đồ trao đổi ""%3"".';
					|ru = 'Тип ""%1"" выбран в определяемом типе ""%2"", но отсутствует в составе плана обмена ""%3"".';
					|en = 'The ""%1"" type is selected in the ""%2"" flexible type collection but is missing in the ""%3"" exchange plan.'; fa = 'The ""%1"" type is selected in the ""%2"" flexible type collection but is missing in the ""%3"" exchange plan.';
					|it = 'Il tipo ""%1"" è selezionato nel tipo definibile ""%2"", ma è assente nella composizione del piano di scambio ""%3"".';
					|pl = 'Typ ""%1"" jest wybrany w określonym typie ""%2"", ale nie ma go w planie wymiany ""%3"".';
					|tr = '""%1"" türü tanımlanan ""%2"" türünde seçildi, ancak ""%3"" değişim planı içeriğinde mevcut değil.'"),
				ValueType,
				NameOfAllLinksType,
				NameOfExchangePlanType));
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateExpressionsInIntegrationRules(Modified_Methods)
	
	If Not IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		Return;
	EndIf;
	
	RuleRequest = New Query(
		"SELECT
		|	AttributeFillingRulesDM.Ref AS Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM AS AttributeFillingRulesDM
		|WHERE
		|	NOT AttributeFillingRulesDM.Ref.DeletionMark
		|	AND AttributeFillingRulesDM.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression)
		|
		|UNION
		|
		|SELECT
		|	AttributeFillingRulesIS.Ref
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS AttributeFillingRulesIS
		|WHERE
		|	NOT AttributeFillingRulesIS.Ref.DeletionMark
		|	AND AttributeFillingRulesIS.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression)");
	RuleSelection_ = RuleRequest.Execute().Select();
	
	While RuleSelection_.Next() Do
		
		RuleObject_ = RuleSelection_.Ref.GetObject(); // CatalogObject.RulesForIntegrationWith1CDocumentManagement
		Try
			RuleObject_.Lock();
		Except
			WriteLogEvent(
				IntegrationWith1CDocumentManagementCore.EventLogEventName(),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		HadChanges = False;
		
		For Each String In RuleObject_.AttributeFillingRulesDM Do
			If String.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
				UpdateExpressionInEmbeddedLanguage(
					String.ComputedExpression,
					HadChanges,
					Modified_Methods);
			EndIf;
		EndDo;
		
		For Each String In RuleObject_.AttributeFillingRulesIS Do
			If String.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
				UpdateExpressionInEmbeddedLanguage(
					String.ComputedExpression,
					HadChanges,
					Modified_Methods);
			EndIf;
		EndDo;
		
		If HadChanges Then
			InfobaseUpdate.WriteData(RuleObject_);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateExpressionInEmbeddedLanguage(ComputedExpression, HadChanges, Modified_Methods)
	
	For Each Method In Modified_Methods Do
		If StrFind(ComputedExpression, Method.Key) Then
			HadChanges = True;
			ComputedExpression = StrReplace(ComputedExpression, Method.Key, Method.Value);
		EndIf;
	EndDo;
	
EndProcedure

// BID update handler for version 1.1.6.1. Updating the names of the integration rules
// and setting the Key details for the types of documents TO.
//
Procedure RestoreVersion_1_1_6_1() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.RestoreVersion_1_1_6_1();
	EndIf;
	
EndProcedure

// BID update handler for version 1.1.8.4. Setting the "Do not create links by links" flag.
//
Procedure RestoreVersion_1_1_8_4() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.RestoreVersion_1_1_8_4();
	EndIf;
	
EndProcedure

// BID update handler for version 1.1.12.2. Setting the mode for changing the data of the completed document.
//
Procedure RestoreVersion_1_1_12_2() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.RestoreVersion_1_1_12_2();
	EndIf;
	
EndProcedure

// BID update handler for version 3.0.1.1. Replacing Integration1 Document management with
// integration1documentofunctionality in expressions in the embedded language in the integration rules.
//
Procedure RestoreVersion_3_0_1_1() Export
	
	UpdateExpressionsInIntegrationRules(Modified_Methods_3_0_1_1());
	
EndProcedure

Function Modified_Methods_3_0_1_1()
	
	Methods = New Map;
	
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ServiceVersion(",
		"IntegrationWith1CDocumentManagementCore.ServiceVersion(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ExecuteQuery(",
		"IntegrationWith1CDocumentManagementCore.ExecuteQuery(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FunctionalityOfServiceVersionIsAvailable(",
		"IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ThereIsUniqueIdentifier(",
		"IntegrationWith1CDocumentManagementCore.ThereIsUniqueIdentifier(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.DependenciesOfConstants(",
		"IntegrationWith1CDocumentManagementCore.DependenciesOfConstants(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.WriteObject(",
		"IntegrationWith1CDocumentManagementCore.WriteObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.WriteObjects(",
		"IntegrationWith1CDocumentManagementCore.WriteObjects(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FillInXDTOPropertyValues(",
		"IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FillInFormDetailsFromXDTO(",
		"IntegrationWith1CDocumentManagementCore.FillInFormDetailsFromXDTO(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FillInDetailsFromConsumer(",
		"IntegrationWith1CDocumentManagementCore.FillInDetailsFromConsumer(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ValueOfAttributeByXDTOObject(",
		"IntegrationWith1CDocumentManagementCore.ValueOfAttributeByXDTOObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.EventLogEventName(",
		"IntegrationWith1CDocumentManagementCore.EventLogEventName(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FindListOfObjects(",
		"IntegrationWith1CDocumentManagementCore.FindListOfObjects(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.NewOutgoingEmail(",
		"IntegrationWith1CDocumentManagementCore.NewOutgoingEmail(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.WebServiceDescription(",
		"IntegrationWith1CDocumentManagementCore.WebServiceDescription(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.BeforeWriteAtServer(",
		"IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FAAuthenticationIsSupported(",
		"IntegrationWith1CDocumentManagementCore.FAAuthenticationIsSupported(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.SuitableType(",
		"IntegrationWith1CDocumentManagementCore.SuitableType(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.GetNewObject(",
		"IntegrationWith1CDocumentManagementCore.GetNewObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.GetObject(",
		"IntegrationWith1CDocumentManagementCore.GetObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.GetObjects(",
		"IntegrationWith1CDocumentManagementCore.GetObjects(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.GetProxy(",
		"IntegrationWith1CDocumentManagementCore.GetProxy(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.UserIsAllowedToUseIntegration(",
		"IntegrationWith1CDocumentManagementCore.UserIsAllowedToUseIntegration(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.MarkForDeletionUncheck(",
		"IntegrationWith1CDocumentManagementCore.MarkForDeletionMarkItem(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.MaximumNumberOfSelectedObjects(",
		"IntegrationWith1CDocumentManagementCore.MaximumNumberOfSelectedObjects(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.PredefinedValueBefore(",
		"IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ObjectTypePresentationXDTO(",
		"IntegrationWith1CDocumentManagementCore.ObjectTypePresentationXDTO(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.CheckWebServiceRefund(",
		"IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ValidateType(",
		"IntegrationWith1CDocumentManagementCore.ValidateType(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.PropertyExists(",
		"IntegrationWith1CDocumentManagementCore.PropertyExists(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.PropertySet(",
		"IntegrationWith1CDocumentManagementCore.PropertySet(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ServerRunsUnderWindows(",
		"IntegrationWith1CDocumentManagementCore.ServerRunsUnderWindows(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ApprovedIn1CDocumentManagement(",
		"IntegrationWith1CDocumentManagementCore.ApprovedIn1CDocumentManagement(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.CreateObjectID(",
		"IntegrationWith1CDocumentManagementCore.CreateObjectID(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.CreateNewObject(",
		"IntegrationWith1CDocumentManagementCore.CreateNewObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.CreateObject(",
		"IntegrationWith1CDocumentManagementCore.CreateObject(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.AbbreviatedNameOfConfiguration(",
		"IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.LinkFromUUID(",
		"IntegrationWith1CDocumentManagementCore.LinkFromUUID(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.LinksToExternalObjects(",
		"IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.Current1CDocumentManagementUser(",
		"IntegrationWith1CDocumentManagementCore.Current1CDocumentManagementUser(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ThisIsObjectValue(",
		"IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ThisIsObjectProperty(",
		"IntegrationWith1CDocumentManagementCore.ThisIsObjectProperty(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.ServiceVersion(",
		"IntegrationWith1CDocumentManagementCoreServerCall.ServiceVersion(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.AddLink(",
		"IntegrationWith1CDocumentManagementCoreServerCall.AddLink(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.WriteWarning(",
		"IntegrationWith1CDocumentManagementCoreServerCall.WriteWarning(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.NameOfMetadataObjectByType(",
		"IntegrationWith1CDocumentManagementCoreServerCall.NameOfMetadataObjectByType(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.TypeNameXDTO(",
		"IntegrationWith1CDocumentManagementCoreServerCall.TypeNameXDTO(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.TypeNameIS(",
		"IntegrationWith1CDocumentManagementCoreServerCall.TypeNameIS(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.UseIntegration(",
		"IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.PasswordKnown(",
		"IntegrationWith1CDocumentManagementCoreServerCall.PasswordKnown(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.TestConnection(",
		"IntegrationWith1CDocumentManagementCoreServerCall.TestConnection(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.TypeIS(",
		"IntegrationWith1CDocumentManagementCoreServerCall.TypeIS(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.DeleteLink(",
		"IntegrationWith1CDocumentManagementCoreServerCall.DeleteLink(");
	
	Return Methods;
	
EndFunction

// BID update handler for version 3.0.2.1. Replacing Integration1 Document management with
// integration1documentofunctionality in expressions in the embedded language in the integration rules.
//
Procedure RestoreVersion_3_0_2_1() Export
	
	NameOfExchangeJob = "IntegrationWith1CDocumentManagementExecuteDataExchange";
	Job = Undefined;
	MetadataJob = Metadata.ScheduledJobs.Find(NameOfExchangeJob);
	If MetadataJob <> Undefined Then
		Job = ScheduledJobsServer.Job(MetadataJob);
	EndIf;
	If TypeOf(Job) = Type("ScheduledJob") Then
		Job.Write();
	EndIf;
	
	UpdateExpressionsInIntegrationRules(Modified_Methods_3_0_2_1());
	
EndProcedure

Function Modified_Methods_3_0_2_1()
	
	Methods = New Map;
	
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FillOutXDTOSignature(",
		"IntegrationWith1CDocumentManagementCore.FillOutXDTOSignature(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FillInTableOfObjectPrintManagers(",
		"IntegrationWith1CDocumentManagementCore.FillInTableOfObjectPrintManagers(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.PrintManagers(",
		"IntegrationWith1CDocumentManagementCore.PrintManagers(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.FormPrintCommands(",
		"IntegrationWith1CDocumentManagementCore.FormPrintCommands(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.DefaultFileTypeOfSavedPrintedForm(",
		"IntegrationWith1CDocumentManagementCore.DefaultFileTypeOfSavedPrintedForm(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagement.ExpansionOfSavedPrintedForm(",
		"IntegrationWith1CDocumentManagementCore.ExpansionOfSavedPrintedForm(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.EnterInformationAboutItemSignatures(",
		"IntegrationWith1CDocumentManagementCoreServerCall.EnterInformationAboutItemSignatures(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.MaximumFileSize_(",
		"IntegrationWith1CDocumentManagementCoreServerCall.MaximumFileSize_(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FillFilesByCopying(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FillFilesByCopying(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.NewFileCreationOptions(",
		"IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.GetStoredFiles(",
		"IntegrationWith1CDocumentManagementCoreServerCall.GetStoredFiles(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.GetFileAndPutItInStorage(",
		"IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.GetVersionOfFileAndPutItInRepository(",
		"IntegrationWith1CDocumentManagementCoreServerCall.GetVersionOfFileAndPutItInRepository(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FileBinaryData(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FileBinaryData(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.BinaryFilesData(",
		"IntegrationWith1CDocumentManagementCoreServerCall.BinaryFilesData(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.UpdateFileWithBinaryTemporaryStorageData(",
		"IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileWithBinaryTemporaryStorageData(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.UnlockFile(",
		"IntegrationWith1CDocumentManagementCoreServerCall.UnlockFile(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.CaptureFile(",
		"IntegrationWith1CDocumentManagementCoreServerCall.CaptureFile(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.GetInformationAboutEditingFile(",
		"IntegrationWith1CDocumentManagementCoreServerCall.GetInformationAboutEditingFile(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.SaveFileEditingInformation(",
		"IntegrationWith1CDocumentManagementCoreServerCall.SaveFileEditingInformation(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FileDetails(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FileDetails(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.PlaceFileSignaturesInStorage(",
		"IntegrationWith1CDocumentManagementCoreServerCall.PlaceFileSignaturesInStorage(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FilesByOwner(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FilesByOwner(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FileVersions(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FileVersions(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.MakeVersionActive(",
		"IntegrationWith1CDocumentManagementCoreServerCall.MakeVersionActive(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FillFileFieldsWithOwnerData(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FillFileFieldsWithOwnerData(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.UpdateListOfFileSignatures(",
		"IntegrationWith1CDocumentManagementCoreServerCall.UpdateListOfFileSignatures(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.FillSignatureListServer(",
		"IntegrationWith1CDocumentManagementCoreServerCall.FillSignatureListServer(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.VerifySignaturesOnServer(",
		"IntegrationWith1CDocumentManagementCoreServerCall.VerifySignaturesOnServer(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.SignDocument(",
		"IntegrationWith1CDocumentManagementCoreServerCall.SignDocument(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.DeleteDocumentSignatures(",
		"IntegrationWith1CDocumentManagementCoreServerCall.DeleteDocumentSignatures(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.GetObjectsForCaption(",
		"IntegrationWith1CDocumentManagementCoreServerCall.GetObjectsForCaption(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.UseElectronicDigitalSignatures(",
		"IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures(");
	Methods.Insert(
		"IntegrationWith1CDocumentManagementServerCall.AttachPrintedFormOfObjectToDocument(",
		"IntegrationWith1CDocumentManagementCoreServerCall.AttachPrintedFormOfObjectToDocument(");
	
	Return Methods;
	
EndFunction

// BID update handler for version 3.0.2.5. Replacing the ID of the action type to fill in the State of the document.
//
Procedure RestoreVersion_3_0_2_5() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo3() Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ModuleIntegrationWith1CDocumentManagement3.RestoreVersion_3_0_2_5();
	EndIf;
	
EndProcedure

// BID update handler for version 3.0.3.1. Transferring settings to a new routine task
// "Data exchange with 1C:Document management", adapted to work in the service mode using 1cFresh technology.
//
Procedure RestoreVersion_3_0_3_1() Export
	
	BeginTransaction();
	Try
		
		JobParameters = New Structure;
		
		NameOfOldExchangeJob = "DeleteIntegrationWith1CWorkflowPerformDataExchange";
		OldAssignment = Undefined;
		OldJobMetadata = Metadata.ScheduledJobs.Find(NameOfOldExchangeJob);
		If OldJobMetadata <> Undefined Then
			OldAssignment = ScheduledJobsServer.Job(OldJobMetadata);
		EndIf;
		If OldAssignment <> Undefined Then
			JobParameters.Insert("Use", OldAssignment.Use);
			JobParameters.Insert("Schedule", OldAssignment.Schedule);
			JobParameters.Insert("RestartCountOnFailure", OldAssignment.RestartCountOnFailure);
			JobParameters.Insert("RestartIntervalOnFailure", OldAssignment.RestartIntervalOnFailure);
			JobParameters.Insert("Key", OldAssignment.Key);
			JobParameters.Insert("UserName", OldAssignment.UserName);
			If OldAssignment.Use Then
				OldAssignment.Use = False;
				OldAssignment.Write();
			EndIf;
		Else
			Use = Not IsBlankString(Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get());
			JobParameters.Insert("Use", Use);
			Schedule = New JobSchedule;
			Schedule.DaysRepeatPeriod = 1;
			Schedule.RepeatPeriodInDay = 120;
			JobParameters.Insert("Schedule", Schedule);
		EndIf;
		
		Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata",
			Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement));
		If Jobs.Count() = 0 Then
			JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement);
			ScheduledJobsServer.AddJob(JobParameters);
		Else
			For Each Job In Jobs Do
				ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
			EndDo;
		EndIf;
		
		CommitTransaction();
		
	Except
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

// The BID update handler for version 3.0.4.2. Processes entries in the tabular part of the rule for filling in the requestionis,
// clears the value of the Attribute of the change mode of the specified valid document for Catalogs.
//
Procedure RestoreVersion_3_0_4_2() Export
	
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2() Then
		ModuleIntegrationWith1CDocumentManagement = Common.CommonModule("IntegrationWith1CDocumentManagement");
		ModuleIntegrationWith1CDocumentManagement.RestoreVersion_3_0_4_2();
	EndIf;
	If IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo3() Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		ModuleIntegrationWith1CDocumentManagement3.RestoreVersion_3_0_4_2();
	EndIf;
	
EndProcedure

#EndRegion