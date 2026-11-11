///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides settings of commands of input on basis.
//
// Parameters:
//  Settings - Structure:
//   * UseInputBasedOnCommands - Boolean - allows using application commands of input on basis
//                                                    instead of the standard ones. The default value is True.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Specifies the list of configuration objects whose manager modules contain the AddGenerationCommands procedure, 
// which creates commands for generating objects based on other objects.
// See the SSL documentation for the procedure syntax.
//
// Parameters:
//   Objects - Array - metadata objects (MetadataObject) with commands of creation on basis.
//
// Example:
//  Objects.Add(Metadata.Catalogs.Companies);
//
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	InventoryInOperationServer.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	NonCurrentAssets.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	RMManagement.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	// ServiceSubsystems.CAERPObjects
	Objects.Add(Metadata.Documents.InternalAcceptanceCertificate);
	Objects.Add(Metadata.Documents.DepositsWithdrawalsByLineOfBusiness);
	Objects.Add(Metadata.Documents.WorkOutput);
	Objects.Add(Metadata.Documents.MovementOfProductsAndMaterials);
	Objects.Add(Metadata.Documents.OrderOfMaterialsForProduction);
	Objects.Add(Metadata.Documents.SubcontractOrder2_5);
	Objects.Add(Metadata.Documents.SubcontractorReport2_5);
	Objects.Add(Metadata.Documents.ProductionPlan);
	Objects.Add(Metadata.Documents.BackflushProduction);
	Objects.Add(Metadata.Documents.RecyclableWasteAllocation);
	Objects.Add(Metadata.Documents.AllocationOfOtherCosts);
	Objects.Add(Metadata.Documents.CalculationOfInventoryImpairmentProvision);
	Objects.Add(Metadata.Documents.SetValuesForNonFinancialItems);
	Objects.Add(Metadata.Catalogs.BillsOfMaterials);
	Objects.Add(Metadata.Documents.AssetActivityRecord);
	Objects.Add(Metadata.Documents.BudgetEntryForm);
	// End ServiceSubsystems.CAERPObjects

	// ServiceSubsystems.ERPObjects
	Objects.Add(Metadata.Documents.MaterialProviderOrder2_5);
	Objects.Add(Metadata.Documents.ProductionOrder2_2);
	Objects.Add(Metadata.Documents.ReportToMaterialProvider2_5);
	Objects.Add(Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
	Objects.Add(Metadata.Documents.BudgetingProcess);
	Objects.Add(Metadata.Documents.EngineeringChangeOrder);
	Objects.Add(Metadata.Documents.ProductionStage2_2);
	Objects.Add(Metadata.DataProcessors.ExecutionOfOperations2_2);
	Objects.Add(Metadata.Documents.StandardCosting2_2);
	Objects.Add(Metadata.Catalogs.RouteSheets);
	Objects.Add(Metadata.Catalogs.TechnologicalProcesses);
	Objects.Add(Metadata.Documents.ProductionOperation2_2);
	Objects.Add(Metadata.Documents.AvailabilityOfWorkCenterType);
	Objects.Add(Metadata.Documents.ShiftTask);
	Objects.Add(Metadata.Documents.WIPOpeningBalancesByProductionLots);
	// End ServiceSubsystems.ERPObjects

	// ServiceSubsystems.ObjectsOfTMCAERP
	Objects.Add(Metadata.Documents.RedemptionOfGoodsFromStorage);
	Objects.Add(Metadata.Documents.RedemptionOfGoodsByCustodian);
	Objects.Add(Metadata.Documents.GoodsShipmentToCustomer);
	Objects.Add(Metadata.Documents.GoodsShipmentFromStorage);
	Objects.Add(Metadata.Documents.TransferOfGoodsToBailee);
	Objects.Add(Metadata.Documents.ReceiptOfGoodsFromCustodian);
	Objects.Add(Metadata.Documents.GoodsReceiptForStorage);
	Objects.Add(Metadata.Documents.WriteOffOfShippedGoods);
	Objects.Add(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer);
	Objects.Add(Metadata.Documents.ReportOnVMIAdjustment);
	Objects.Add(Metadata.Documents.MisgradingOfGoodsAtCustodian);
	Objects.Add(Metadata.Documents.DamageAtCustodian);
	Objects.Add(Metadata.Documents.ExpenseReport);
	Objects.Add(Metadata.Documents.CustomerInvoiceServices);
	Objects.Add(Metadata.Documents.GoodsQualityControlCertificate);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingShipment);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingTransfer);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt);
	Objects.Add(Metadata.Documents.CustomerBonusCertificate);
	Objects.Add(Metadata.Documents.GiftCertificateCancellation);
	Objects.Add(Metadata.Documents.OBEntry);
	Objects.Add(Metadata.Documents.OBEntryARAP);
	Objects.Add(Metadata.Documents.OBEntryCash);
	Objects.Add(Metadata.Documents.OBEntrySalesForPastPeriods);
	Objects.Add(Metadata.Documents.OBEntryFinancialInstruments);
	Objects.Add(Metadata.Documents.OBEntryOtherExpenses);
	Objects.Add(Metadata.Documents.OBEntryOtherAssetsAndLiabilities);
	Objects.Add(Metadata.Documents.OBEntryAcquiringContractARAP);
	Objects.Add(Metadata.Documents.OBEntryARAPAdvanceHolders);
	Objects.Add(Metadata.Documents.OBEntryGoods);
	Objects.Add(Metadata.Documents.ARAPSettlement);
	Objects.Add(Metadata.Documents.InventoryConsumption);
	Objects.Add(Metadata.Documents.IntercompanyGoodsReturn);
	Objects.Add(Metadata.Documents.ReturnOfGoodsFromCustomer);
	Objects.Add(Metadata.Documents.ReturnOfGoodsToVendor);
	Objects.Add(Metadata.Documents.DepositCashIntoCashRegister);
	Objects.Add(Metadata.Documents.ReturnOfGiftCards);
	Objects.Add(Metadata.Documents.CashWithdrawalFromCashRegister);
	Objects.Add(Metadata.Documents.ReturnablePackagingRedemptionByCustomer);
	Objects.Add(Metadata.Documents.RedemptionOfReturnablePackagingFromVendor);
	Objects.Add(Metadata.Documents.MovementOfOtherAssetsAndLiabilities);
	Objects.Add(Metadata.Documents.IssuedLetterOfAuthority);
	Objects.Add(Metadata.Documents.TransportationJob);
	Objects.Add(Metadata.Documents.JobForSalesRepresentative);
	Objects.Add(Metadata.Documents.SalesOrder);
	Objects.Add(Metadata.Documents.InventoryConsumptionOrder);
	Objects.Add(Metadata.Documents.DeliveryOrder);
	Objects.Add(Metadata.Documents.TransferOrder);
	Objects.Add(Metadata.Documents.ByAssemblyDisassemblyOrder);
	Objects.Add(Metadata.Documents.PurchaseOrder);
	Objects.Add(Metadata.Documents.PurchaseRequest);
	Objects.Add(Metadata.Documents.ApplicationForCollateral);
	Objects.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	Objects.Add(Metadata.Documents.ApplicationForBusinessTrip);
	Objects.Add(Metadata.Documents.RequestForGoodsQualityControl);
	Objects.Add(Metadata.Documents.PaymentRequest);
	Objects.Add(Metadata.Documents.ProductRangeChange);
	Objects.Add(Metadata.Documents.PhysicalCountReport);
	Objects.Add(Metadata.Documents.PhysicalCountOfCashAccounts);
	Objects.Add(Metadata.Documents.CommercialProposalForCustomer);
	Objects.Add(Metadata.Documents.ARAPAccountingScheduleAdjustment);
	Objects.Add(Metadata.Documents.ARAPAdjustment);
	Objects.Add(Metadata.Documents.ARAPAdjustmentFinancialInstruments);
	Objects.Add(Metadata.Documents.InventoryAdjustmentSurplusesAndShortages);
	Objects.Add(Metadata.Documents.InventoryAssignmentAdjustment);
	Objects.Add(Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder);
	Objects.Add(Metadata.Documents.PurchaseAdjustment);
	Objects.Add(Metadata.Documents.SaleAdjustment);
	Objects.Add(Metadata.Documents.AdjustmentOfARAPAccountingForAdvanceHolders);
	Objects.Add(Metadata.Documents.RegisterAdjustment);
	Objects.Add(Metadata.Documents.CashFlowLimits);
	Objects.Add(Metadata.Documents.AccrueAndDeductionOfBonusPoints);
	Objects.Add(Metadata.Documents.LoanAndDepositInterestCharge);
	Objects.Add(Metadata.Documents.SalesPlansAllocationBaseByCategories);
	Objects.Add(Metadata.Documents.PlannedCashReceipt);
	Objects.Add(Metadata.Documents.PaymentCardTransaction);
	Objects.Add(Metadata.Documents.InventorySurplusRecognition);
	Objects.Add(Metadata.Documents.GoodsSurplusesNote);
	Objects.Add(Metadata.Documents.GoodsShortageNote);
	Objects.Add(Metadata.Documents.GoodsMisgradingNote);
	Objects.Add(Metadata.Documents.DamageNote);
	Objects.Add(Metadata.Documents.GoodsTransferNote);
	Objects.Add(Metadata.Documents.GoodsPickingPlacement);
	Objects.Add(Metadata.Documents.CashDepositWithdrawalDiscrepancies);
	Objects.Add(Metadata.Documents.BankReportOnAcquiringTransactions);
	Objects.Add(Metadata.Documents.ConsignmentReportFromCustomer);
	Objects.Add(Metadata.Documents.WriteOffReportFromCommissionAgent);
	Objects.Add(Metadata.Documents.ConsignmentReportToVendor);
	Objects.Add(Metadata.Documents.PurchaseInvoiceConsignmentStockLost);
	Objects.Add(Metadata.Documents.RetailSalesReport);
	Objects.Add(Metadata.Documents.CommissionReportIntercompany);
	Objects.Add(Metadata.Documents.CommissionWriteOffReportIntercompany);
	Objects.Add(Metadata.Documents.CustomerInvoiceIntercompany);
	Objects.Add(Metadata.Documents.InventoryTransfer);
	Objects.Add(Metadata.Documents.GoodsMisgrading);
	Objects.Add(Metadata.Documents.InventoryRecount);
	Objects.Add(Metadata.Documents.PurchasePlan);
	Objects.Add(Metadata.Documents.PlanOfGoodsStock);
	Objects.Add(Metadata.Documents.SalesPlan);
	Objects.Add(Metadata.Documents.SalesPlanByCategories);
	Objects.Add(Metadata.Documents.AssemblyDisassemblyPlan);
	Objects.Add(Metadata.Documents.InventoryConsumptionPlan);
	Objects.Add(Metadata.Documents.GoodsDamage);
	Objects.Add(Metadata.Documents.BankAccountReceiptNote);
	Objects.Add(Metadata.Documents.ReceiptOfGoodsToWarehouse);
	Objects.Add(Metadata.Documents.GoodsReceiptFromCustomer);
	Objects.Add(Metadata.Documents.ReceiptOfServicesToBusinessUnit);
	Objects.Add(Metadata.Documents.VendorInvoice);
	Objects.Add(Metadata.Documents.VendorInvoiceServicesAndAssets);
	Objects.Add(Metadata.Documents.CashAccountReceiptNote);
	Objects.Add(Metadata.Documents.GoodsReceiptNote);
	Objects.Add(Metadata.Documents.OtherGoodsRecordingAsReceived);
	Objects.Add(Metadata.Documents.OtherIncomeExpenses);
	Objects.Add(Metadata.Documents.CashTransferReferenceOrder);
	Objects.Add(Metadata.Documents.AllocationOfIncomeByLinesOfBusiness);
	Objects.Add(Metadata.Documents.DeferredExpensesAllocation);
	Objects.Add(Metadata.Documents.MailoutToCustomers);
	Objects.Add(Metadata.Documents.CashVoucher);
	Objects.Add(Metadata.Documents.GoodsIssueNote);
	Objects.Add(Metadata.Documents.ExchangeDifferenceCalculation);
	Objects.Add(Metadata.Documents.CalculationOfDiscountInterestExpenses);
	Objects.Add(Metadata.Documents.InventoryCostCalculation);
	Objects.Add(Metadata.Documents.GiftCertificateSale);
	Objects.Add(Metadata.Documents.CustomerInvoice);
	Objects.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets);
	Objects.Add(Metadata.Documents.VendorPriceList);
	Objects.Add(Metadata.Documents.Trip);
	Objects.Add(Metadata.Documents.AssemblyFromComponents);
	Objects.Add(Metadata.Documents.ARAPReconciliation2_4);
	Objects.Add(Metadata.Documents.ARAPReconciliation2_5_11);
	Objects.Add(Metadata.Documents.BankAccountIssue);
	Objects.Add(Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	Objects.Add(Metadata.Documents.WriteOffOfGoodsShortages);
	Objects.Add(Metadata.Documents.CustomerCommercialInvoice);
	Objects.Add(Metadata.Documents.CCDImport);
	Objects.Add(Metadata.Documents.PackingList);
	Objects.Add(Metadata.Documents.ConditionsOfCustomerRebates);
	Objects.Add(Metadata.Documents.ConditionsOfVendorRebates);
	Objects.Add(Metadata.Documents.AccrualOfCustomerRebates);
	Objects.Add(Metadata.Documents.AccrualOfVendorRebates);
	Objects.Add(Metadata.Documents.SetStorageBinLocks);
	Objects.Add(Metadata.Documents.SetProductRangeQuotas);
	Objects.Add(Metadata.Documents.PriceSetup);
	Objects.Add(Metadata.DataProcessors.WorkplaceOfDeliveryOfficer);
	Objects.Add(Metadata.DataProcessors.InboundWarehouseMangement);
	Objects.Add(Metadata.Catalogs.ItemKinds);
	Objects.Add(Metadata.Catalogs.CounterpartyContracts);
	Objects.Add(Metadata.Catalogs.LoanAndDepositContracts);
	Objects.Add(Metadata.Catalogs.ContactPersonsForPartners);
	Objects.Add(Metadata.Catalogs.Counterparties);
	Objects.Add(Metadata.Catalogs.Products);
	Objects.Add(Metadata.Catalogs.StorageAreas);
	Objects.Add(Metadata.Catalogs.Partners);
	Objects.Add(Metadata.Catalogs.GiftCertificates);
	Objects.Add(Metadata.Catalogs.LoyaltyCards);
	Objects.Add(Metadata.Catalogs.Complaints); 
	Objects.Add(Metadata.Catalogs.ProductSegments);
	Objects.Add(Metadata.Catalogs.PartnersSegments);
	Objects.Add(Metadata.Catalogs.TermsOfSale);
	Objects.Add(Metadata.Catalogs.SalesOpportunitiesToCustomer);
	Objects.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors);
	Objects.Add(Metadata.Catalogs.Warehouses);
	Objects.Add(Metadata.Catalogs.Warerooms); 
	Objects.Add(Metadata.Catalogs.StorageBins); 
	Objects.Add(Metadata.Catalogs.TypesOfPrices);
	Objects.Add(Metadata.Catalogs.ProductKitConfigurations); 
	Objects.Add(Metadata.Catalogs.LoyaltyCardKinds);
	
	
	Objects.Add(Metadata.Documents.PurchasingReportToConsignorPrincipal);
	Objects.Add(Metadata.Documents.SourceDocument);
	
	VATAccountingERP.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	FinancialAccountingOfGeneralPurpose.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	// End ServiceSubsystems.ObjectsOfTMCAERP
	
	GenerateFromLocalization.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	
	
EndProcedure

// Called once to generate the GenerationCommands list when it is first
// required. After that, the result is cached by the memorization module.
// Here you can define generation commands that are common for most configuration objects.
//
// Parameters:
//   GenerationCommands - ValueTable - Generated commands to be shown in the submenu:
//     
//     Common settings
//       * Id - String - Command ID.
//     
//     Appearance settings:
//       * Presentation - String   - Command presentation in a form.
//       * Importance      - String   - a submenu group to display the command in.
//                                    The following values are acceptable: "Important", "Ordinary", and "SeeAlso".
//       * Order       - Number    - an order of placing the command in the submenu. It is used to set up a particular
//                                    workplace.
//       * Picture      - Picture - a command picture.
//     
//     Visibility and availability settings:
//       * ParameterType - TypeDescription - types of objects that the command is intended for.
//       * VisibilityInForms    - String - Comma-delimited names of the forms to add a command to.
//                                        Use to add different set of commands to different forms.
//       * FunctionalOptions - String - Comma-delimited names of functional options that affect the command visibility.
//       * VisibilityConditions    - Array - Defines the command conditional visibility.
//                                        To add conditions, use procedure AttachableCommands.AddCommandVisibilityCondition().
//                                        Use "And" to specify multiple conditions.
//                                        
//       * ChangesSelectedObjects - Boolean - defines whether the command is available in case
//                                        a user is not authorized to edit the object.
//                                        If True, the button will be unavailable.
//                                        Optional. The default value is False.
//     
//     Execution process settings:
//       * MultipleChoice - Boolean
//                            - Undefined - if True, then the command supports multiple choice.
//             In this case, the parameter is passed via a list.
//             Optional. Default value is False.
//       * WriteMode - String - actions associated with object writing that are executed before the command handler.
//             "DoNotWrite"          - do not write the object and pass
//                                       the full form in the handler parameters instead of references. In this mode, we recommend that you operate directly with a form
//                                       that is passed in the structure of parameter 2 of the command handler.
//             "WriteNewOnly" - Write only new objects.
//             "Write"            - Write only new and modified objects.
//             "Post"             - Post documents.
//             Before writing or posting the object, users are asked for confirmation.
//             Optional. Default value is "Write".
//       * FilesOperationsRequired - Boolean - If True, in the web client, users are prompted
//             to install 1C:Enterprise Extension.
//             Optional. The default value is False.
//     
//     Handler settings:
//       * Manager - String - an object responsible for executing the command.
//       * FormName - String - name of the form to be retrieved for the command execution.
//             If Handler is not specified, the "Open" form method is called.
//       * FormParameters - Undefined
//                        - FixedStructure - -- optional. Form parameters specified in FormName.
//       * Handler - String - details of the procedure that handles the main action of the command.
//             Format "<CommonModuleName>.<ProcedureName>" is used when the procedure is in a common module.
//             Format "<ProcedureName>" is used in the following cases:
//               1) If FormName is filled, a client procedure is expected in the specified form module.
//               2) If FormName is not filled, a server procedure is expected in the manager module.
//       * AdditionalParameters - FixedStructure - optional. Parameters of the handler specified in Handler.
//   
//   Parameters - Structure - information about execution context:
//       * FormName - String - Form full name.
//
//   StandardProcessing - Boolean - If False, the object manager's AddGenerationCommands event
//                                   is not called.
//
Procedure BeforeAddGenerationCommands(GenerationCommands, Parameters, StandardProcessing) Export
	
	GenerateFromLocalization.BeforeAddGenerationCommands(GenerationCommands, Parameters, StandardProcessing);
	
	FormName = Parameters.FormName;
	FieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FormName,".");
	If FieldArray.Count() < 4 Then
		Return;
	EndIf;
	
	If (GetFunctionalOption("UseAdditionalDataProcessorsForRelatedObjectCreation", 
				New Structure("AdditionalReportsAndDataProcessorsRelatedObject,AdditionalReportsAndDataProcessorsFormType", 
				Catalogs.MetadataObjectIDs.FindByAttribute("FullName",FieldArray[0]+"."+FieldArray[1]), FieldArray[3]))
			Or GetFunctionalOption("UseAdditionalDataProcessorsForRelatedObjectCreation", 
				New Structure("AdditionalReportsAndDataProcessorsRelatedObject,AdditionalReportsAndDataProcessorsFormType", 
				Catalogs.MetadataObjectIDs.FindByAttribute("FullName",FieldArray[0]+"."+FieldArray[1]), 
				?(StrFind(FieldArray[3], "ListForm") <> 0,AdditionalReportsAndDataProcessorsClientServer.ListFormType(),
				AdditionalReportsAndDataProcessorsClientServer.ObjectFormType())))) 
			And StrFind(FormName,"DocumentJournal") = 0 Then
		
		CreationBasedOnCommand = GenerationCommands.Add();
		CreationBasedOnCommand.Handler = "GenerationByReferenceTMClient.RelatedObjectsCreation";
		CreationBasedOnCommand.Id = "RelatedObjectsCreation";
		CreationBasedOnCommand.Presentation = NStr("vi = 'Tạo đối tượng liên quan...';
													|ru = 'Создание связанных объектов...';
													|en = 'Creating related objects...'; fa = 'Creating related objects...';
													|it = 'Creazione di oggetti connessi...';
													|pl = 'Tworzenie powiązanych obiektów...';
													|tr = 'Bağlantılı nesnelerin oluşumu...'");
		CreationBasedOnCommand.WriteMode = "Post";
		CreationBasedOnCommand.MultipleChoice = True;
		CreationBasedOnCommand.Order = 100;
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeAddGenerationCommands(
		GenerationCommands,
		Parameters,
		StandardProcessing);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

// Defines the list of generation commands. Called before the object manager's
// AddGenerationCommands call.
//
// Parameters:
//  Object - MetadataObject - an object for which the commands are added.
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//  StandardProcessing - Boolean - If False, the object manager's AddGenerationCommands event
//                                  is not called.
//
Procedure OnAddGenerationCommands(Object, GenerationCommands, Parameters, StandardProcessing) Export
	If Object = Metadata.Documents.PhoneCall Then
		Catalogs.SalesOpportunitiesToCustomer.AddGenerateCommand(GenerationCommands);
		Catalogs.Complaints.AddGenerateCommand(GenerationCommands)
	EndIf;
	If Object = Metadata.Documents.Meeting Then
		Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	EndIf;
	If Object = Metadata.Documents.IncomingEmail Then
		Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	EndIf;
	If Object = Metadata.Documents.PlannedInteraction Then
		BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	EndIf;
	
EndProcedure

#EndRegion