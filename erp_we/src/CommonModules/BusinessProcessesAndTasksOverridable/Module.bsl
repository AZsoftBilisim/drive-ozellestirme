///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The procedure is called to update business process data in the BusinessProcessesData information register.
//
// Parameters:
//  Record - InformationRegisterRecord.BusinessProcessesData - a business process record.
//
Procedure OnWriteBusinessProcessesList(Record) Export
	
EndProcedure

// The procedure is called to check whether the current user has rights
// to suspend and resume a business process.
//
// Parameters:
//  BusinessProcess        - DefinedType.BusinessProcessObject
//  HasRights            - Boolean - If False, the rights are denied.
//  StandardProcessing - Boolean - If False, the standard rights check is skipped.
//
Procedure OnCheckStopBusinessProcessRights(BusinessProcess, HasRights, StandardProcessing) Export
	
	StandardProcessing = True;	

EndProcedure

// The procedure is called to fill in the MainTask attribute from filling data.
//
// Parameters:
//  BusinessProcessObject  - DefinedType.BusinessProcessObject
//  FillingData     - Arbitrary        - filling data that is passed to the filling handler.
//  StandardProcessing - Boolean              - If False, the standard filling processing is
//                                               skipped.
//
Procedure OnFillMainBusinessProcessTask(BusinessProcessObject, FillingData, StandardProcessing) Export
	
	StandardProcessing = True;	
	
EndProcedure

// The function is called to fill in the task form parameters.
//
// Parameters:
//  BusinessProcessName           - String                         - a business process name.
//  TaskRef                - TaskRef.PerformerTask
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef.Job - action.
//  FormParameters              - Structure:
//   * FormName       - Form name to pass to the OpenForm method. 
//   * FormParameters - parameters of the form to be opened.
//
// Example:
//  If BusinessProcessName = "Job" Then
//      FormName = "BusinessProcess.Job.Form.ExternalAction" + BusinessProcessRoutePoint.Name;
//      FormParameters.Insert("FormName", FormName);
//  EndIf;
//
Procedure OnReceiveTaskExecutionForm(BusinessProcessName, TaskRef,
	BusinessProcessRoutePoint, FormParameters) Export
	BusinessProcessesAndTasksLocalization.OnReceiveTaskExecutionForm(BusinessProcessName, TaskRef, BusinessProcessRoutePoint, FormParameters);
EndProcedure

// Fills in the list of business processes that are attached to the subsystem
// and their manager modules contain the following export procedures and functions:
//  - OnForwardTask.
//  - TaskExecutionForm.
//  - DefaultCompletionHandler.
//
// Parameters:
//   AttachedBusinessProcesses - Map of KeyAndValue:
//     * Key - String - a full name of the metadata object attached to the subsystem;
//     * Value - String - empty string.
//
// Example:
//   AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.JobWithRoleAddressing.FullName(), "");
//
Procedure OnDetermineBusinessProcesses(AttachedBusinessProcesses) Export
	
	BusinessProcessesAndTasksLocalization.OnDetermineBusinessProcesses(AttachedBusinessProcesses);
	
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.Job.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.ApprovalOfInventoryConsumptionOrder.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.PurchaseApproval.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.SaleApproval.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.PriceApproval.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.StandardSale.FullName(), "");
	AttachedBusinessProcesses.Insert(Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders.FullName(), "");
EndProcedure

// It is called from the BusinessProcessesAndTasks subsystem object modules
// to set up restriction logic in the application.
//
// For the example of filling access value sets, see comments
// to AccessManagement.FillAccessValuesSets.
//
// Parameters:
//  Object - BusinessProcessObject.Job - an object for which the sets are populated.
//  Table - See AccessManagement.AccessValuesSetsTable
//
Procedure OnFillingAccessValuesSets(Object, Table) Export
	
	BusinessProcessesAndTasksLocalization.OnFillingAccessValuesSets(Object, Table);
	
EndProcedure

// Called by the PerformerRoles catalog manager module at the business role initial population.
// 
//
// Parameters:
//  LanguagesCodes - Array of String - a list of configuration languages. Relevant to multilingual configurations.
//  Items   - ValueTable - filling data. Column content matches the attribute set 
//                                 of the PerformerRoles catalog.
//  TabularSections - Structure - object table details where:
//   * Key - String - Table name.
//   * Value - ValueTable - Value table.
//                                  Its structure must be copied before population. For example:
//                                  Item.Keys = TabularSections.Keys.Copy();
//                                  TSItem = Item.Keys.Add();
//                                  TSItem.KeyName = "Primary";
//
Procedure OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections) Export

	BusinessProcessesAndTasksLocalization.OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections);
	
	#Region ApproverInventoryConsumptionOrder
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverInventoryConsumptionOrder";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Người thống nhất đơn hàng tiêu dùng nội bộ';
																					|ru = 'Согласующий заказы на внутреннее потребление';
																					|en = 'Approver of inventory consumption orders';
																					|it = 'Согласующий заказы на внутреннее потребление';
																					|pl = 'Approver of inventory consumption orders';
																					|tr = 'İç tüketimde eşleşen siparişler'", LanguagesCodes); // @NStr-2
	Item.Code = "000000020";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion
	
	#Region ApproverOfRequestsForReturnOfGoodsFromCustomers
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverOfRequestsForReturnOfGoodsFromCustomers";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất giấy đề nghị trả lại hàng từ khách hàng';
																					|ru = 'Согласующий заявки на возврат товаров от клиентов';
																					|en = 'Approver of sales return requests';
																					|it = 'Coordinatore delle richieste di reso della merce dai clienti';
																					|pl = 'Uzgadniający zgłoszenia do zwrotu towarów od klientów';
																					|tr = 'Satış iadesi taleplerini onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000007";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverPurchaseCommercialTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverPurchaseCommercialTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đồng ý về các điều khoản thương mại khi mua hàng';
																					|ru = 'Согласующий коммерческие условия закупок';
																					|en = 'Approver of purchase commercial terms';
																					|it = 'Coordinatore delle condizioni commerciali degli acquisti';
																					|pl = 'Uzgadniający warunki handlowe zakupów';
																					|tr = 'Satın almaların ticari hüküm ve koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000008";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverSalesCommercialTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverSalesCommercialTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đồng ý về các điều khoản thương mại khi bán hàng';
																					|ru = 'Согласующий коммерческие условия продаж';
																					|en = 'Approver of sales commercial terms';
																					|it = 'Coordinatore delle condizioni commerciali delle vendite';
																					|pl = 'Uzgadniający warunki handlowe sprzedaży';
																					|tr = 'Satışların ticari hüküm ve koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000005";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverPurchaseLogisticsTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverPurchaseLogisticsTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đồng ý về các điều khoản logistic khi mua hàng';
																					|ru = 'Согласующий логистические условия закупок';
																					|en = 'Approver of purchase logistics terms';
																					|it = 'Coordinatore delle condizioni di trasporto degli acquisti';
																					|pl = 'Uzgadniający warunki logistyczne zakupów';
																					|tr = 'Satın almaların lojistik koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000011";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverSalesLogisticsTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverSalesLogisticsTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Đồng ý về các điều khoản logistic khi bán hàng';
																					|ru = 'Согласующий логистические условия продаж';
																					|en = 'Approver of sales logistics terms';
																					|it = 'Coordinatore delle condizioni di trasporto delle vendite';
																					|pl = 'Uzgadniający logistyczne handlowe sprzedaży';
																					|tr = 'Satışların lojistik koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000004";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverProductPricing
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverProductPricing";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất đặt giá mặt hàng';
																					|ru = 'Согласующий установки цен номенклатуры';
																					|en = 'Approver of product pricing';
																					|it = 'Coordinatore dell''impostazione dei prezzi degli articoli';
																					|pl = 'Uzgadniający ustawienia cen produktów';
																					|tr = 'Ürün fiyatlarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000006";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverPurchaseFinancialTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverPurchaseFinancialTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất điều khoản tài chính khi mua hàng';
																					|ru = 'Согласующий финансовые условия закупок';
																					|en = 'Approver of purchase financial terms';
																					|it = 'Coordinatore delle condizioni finanziarie degli acquisti';
																					|pl = 'Uzgadniający warunki finansowe zakupów';
																					|tr = 'Satın almaların mali koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000010";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverSalesFinancialTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverSalesFinancialTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất điều khoản tài chính khi bán hàng';
																					|ru = 'Согласующий финансовые условия продаж';
																					|en = 'Approver of sales financial terms';
																					|it = 'Coordinatore delle condizioni finanziarie delle vendite';
																					|pl = 'Uzgadniający warunki finansowe sprzedaży';
																					|tr = 'Satışların mali koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000003";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverPurchasePriceTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverPurchasePriceTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất điều khoản giá khi mua hàng';
																					|ru = 'Согласующий ценовые условия закупок';
																					|en = 'Approver of purchase price terms';
																					|it = 'Coordinatore delle condizioni di trasporto degli acquisti';
																					|pl = 'Uzgadniający warunki cenowe zakupów';
																					|tr = 'Satın almaların fiyat koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000009";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion

	#Region ApproverSalesPriceTerms
	Item = Items.Add();
	Item.PredefinedDataName = "ApproverSalesPriceTerms";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "vi = 'Thống nhất điều khoản giá khi bán hàng';
																					|ru = 'Согласующий ценовые условия продаж';
																					|en = 'Approver of sales price terms';
																					|it = 'Coordinatore delle condizioni di prezzo delle vendite';
																					|pl = 'Uzgadniający warunki cenowe sprzedaży';
																					|tr = 'Satışların fiyat koşullarını onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000002";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion
	
	#Region ApprovingPermitsForReplacementOfMaterials
	Item = Items.Add();
	Item.PredefinedDataName = "ApprovingPermitsForReplacementOfMaterials";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description", "ru = 'Согласующий разрешения на замену материалов';
																					|vi = 'Engineering change order approver';
																					|en = 'Engineering change order approver';
																					|it = 'Engineering change order approver';
																					|pl = 'Engineering change order approver';
																					|tr = 'Mühendislik değişimi emirlerini onaylayan'", LanguagesCodes); // @NStr-2
	Item.Code = "000000023";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects = False;
	Item.ExternalRole = False;
	
	Purpose = TabularSections.Purpose.Copy(); // CatalogTabularSection.PerformerRoles.Purpose -
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	#EndRegion
	
EndProcedure

// Called by the PerformerRoles catalog manager module at the business role initial population.
// 
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - filling data.
//  AdditionalParameters - Structure
//
Procedure AtInitialPerformerRoleFilling(Object, Data, AdditionalParameters) Export
	
	Return;
	
EndProcedure

// Called by the CCT TaskAddressingObjects manager module on the task initial population.
// Standard attribute ValueType must populated in the OnInitialFillingTaskAddressingObjectItem procedure.
// 
//
// Parameters:
//  LanguagesCodes - Array of String - a list of configuration languages. Relevant to multilingual configurations.
//  Items   - ValueTable - filling data. Column content matches the attribute set of the TaskAddressingObjects CCT object.
//  TabularSections - Structure - object table details where:
//   * Key - String - Table name.
//   * Value - ValueTable - Value table.
//                                  Its structure must be copied before population. For example:
//                                  Item.Keys = TabularSections.Keys.Copy();
//                                  TSItem = Item.Keys.Add();
//                                  TSItem.KeyName = "Primary";
//
Procedure OnInitialFillingTasksAddressingObjects(LanguagesCodes, Items, TabularSections) Export
	
	
	
EndProcedure

// Called by the CCT TaskAddressingObjects manager module on the task initial population.
// 
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.TaskAddressingObjects - Object to populate.
//  Data                  - ValueTableRow - filling data.
//  AdditionalParameters - Structure
//
Procedure OnInitialFillingTaskAddressingObjectItem(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion
