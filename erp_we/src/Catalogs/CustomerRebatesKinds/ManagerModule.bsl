//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
//  Array of String
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array; // Array of String
	Result.Add("ProductItemProperty");
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// Prepares the print data.
// 
// Parameters:
//  DataSources - See PrintManagementOverridable.WhenPreparingPrintData.DataSources
//  ExternalDataSets - See PrintManagementOverridable.WhenPreparingPrintData.ExternalDataSets
//  LanguageCode - See PrintManagementOverridable.WhenPreparingPrintData.LanguageCode
//  AdditionalParameters - See PrintManagementOverridable.WhenPreparingPrintData.AdditionalParameters
// 
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, LanguageCode, AdditionalParameters) Export
	
	ExternalDataSets.Insert("Data", TheseArePropertiesOfNomenclature(DataSources));
	
EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
	
	Return NotAttributesToEdit;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region Other

// The type of retro bonus is used in documents
// 
// Parameters:
//  Object - CatalogObject.CustomerRebatesKinds -
//  	   - See Catalog.CustomerRebatesKinds.Form.ItemForm.Object 
//  CheckWithBlocking - Boolean - Check with a lock on documents
// 
// Returns:
//  Boolean - Rebate Kind Is Used
//
Function RebateKindIsUsed(Object, CheckWithBlocking = False) Export
	
	If Object.Ref.IsEmpty() Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	If CheckWithBlocking Then
		
		Block = New DataLock;
		
		LockItem = Block.Add("Document.ConditionsOfCustomerRebates");
		LockItem.SetValue("RebateKind", Object.Ref);
		LockItem.Mode = DataLockMode.Shared;
		
		// Called from an external record transaction
		//@skip-check lock-out-of-try
		Block.Lock();
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("RebateKind", Object.Ref);
	Query.Text =
	"SELECT TOP 1
	|	ConditionsOfCustomerRebates.Ref
	|FROM
	|	Document.ConditionsOfCustomerRebates AS ConditionsOfCustomerRebates
	|WHERE
	|	ConditionsOfCustomerRebates.RebateKind = &RebateKind";
	Result = Query.Execute();
	Return Not Result.IsEmpty();
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array of String - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	ConfigurationModule = FinancialReportingServer;
	
	SettingUpFieldSelectionOfParticipants(Settings, ConfigurationModule);
	SettingUpFieldWithoutCalculation(Settings, ConfigurationModule);
	SettingUpGoodsIndicatorField(Settings, ConfigurationModule);
	SettingUpSalesCalculationBaseField(Settings, ConfigurationModule);
	SettingUpConditionTimeFenceField(Settings, ConfigurationModule);
	SettingUpFieldThatIncludesVAT(Settings, ConfigurationModule);
	SettingUpMembershipField(Settings, ConfigurationModule);
	SettingUpGoodsCompositionField(Settings, ConfigurationModule);
	SettingUpSelectionOfGoodsField(Settings, ConfigurationModule);
	SettingUpDistributionOrderField(Settings, ConfigurationModule);
	SettingUpAccrualTimeFenceField(Settings, ConfigurationModule);
	SettingUpItemPropertyField(Settings, ConfigurationModule);
	SettingUpUsageDecorationField(Settings, ConfigurationModule);
	
EndProcedure

// Sets the Status of the retro bonus type
//
// Parameters:
//	RebateKinds - Array of CatalogRef.CustomerRebatesKinds - Array of links to types of retro bonuses
//	Status - EnumRef.RebatesKindsStatuses - The Status that will be set for the types of retro bonuses
//
// Returns:
//	Number - the number of processed objects.
//
Function SetStatus(Val RebateKinds, Val Status) Export
	
	SetPrivilegedMode(True);
	
	ReferencesArrray = New Array(); // Array of CatalogRef.CustomerRebatesKinds
	ProcessedItemsCount = 0;
	
	For Each RebateKind In RebateKinds Do
		
		If TypeOf(RebateKind) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(RebateKind);
		
	EndDo;
	
	If ReferencesArrray = 0 Then
		Return ProcessedItemsCount;
	EndIf;
	
	AttributesOfTypes = SelectionOfPropsTypes(ReferencesArrray, Status); 
	
	While AttributesOfTypes.Next() Do
		
		If AttributesOfTypes.DeletionMark Then
			
			ErrorTemplate = NStr("vi = 'Dạng thưởng lũy kế ""%1"" đã bị đặt dấu xóa. Bỏ qua thay đổi trạng thái.';
								|ru = 'Вид ретро-бонуса ""%1"" помечен на удаление. Изменение статуса пропущено.';
								|en = 'The ""%1"" rebate kind is marked for deletion. Status change is skipped.'; fa = 'The ""%1"" rebate kind is marked for deletion. Status change is skipped.';
								|it = 'Вид ретро-бонуса ""%1"" помечен на удаление. Изменение статуса пропущено.';
								|pl = 'The ""%1"" rebate kind is marked for deletion. Status change is skipped.';
								|tr = '""%1"" retro bonusu türü silinmeye alındı. Durum değişimi başlatıldı.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate,
				AttributesOfTypes.Presentation);
			Common.MessageToUser(ErrorText, AttributesOfTypes.Ref);
			Continue;
			
		EndIf;
		
		If AttributesOfTypes.StatusMatches Then
			
			ErrorTemplate = NStr("vi = 'Dạng thưởng lũy kế ""%1"" đã được gán trạng thái ""%2""';
								|ru = 'Виду ретро-бонуса ""%1"" уже присвоен статус ""%2""';
								|en = 'The ""%1"" rebate kind is already in the ""%2"" status'; fa = 'The ""%1"" rebate kind is already in the ""%2"" status';
								|it = 'Виду ретро-бонуса ""%1"" уже присвоен статус ""%2""';
								|pl = 'The ""%1"" rebate kind is already in the ""%2"" status';
								|tr = '""%1"" retro bonusunun türü halihazırda ""%2"" durumuna sahip'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate,
				AttributesOfTypes.Presentation,
				String(Status));
			Common.MessageToUser(ErrorText, AttributesOfTypes.Ref);
			Continue;
			
		EndIf;
		
		Try
			
			LockDataForEdit(AttributesOfTypes.Ref);
			
		Except
			
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorTemplate = NStr("vi = 'Không thể phong tỏa dạng thưởng lũy kế ""%1"". %2';
								|ru = 'Не удалось заблокировать вид ретро-бонуса""%1"". %2';
								|en = 'Cannot lock the ""%1"" rebate kind. %2'; fa = 'Cannot lock the ""%1"" rebate kind. %2';
								|it = 'Не удалось заблокировать вид ретро-бонуса""%1"". %2';
								|pl = 'Cannot lock the ""%1"" rebate kind. %2';
								|tr = '""%1"" retro bonusunun türü engellenemedi. %2'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorTemplate,
				AttributesOfTypes.Presentation,
				ErrorDescription);
			Common.MessageToUser(ErrorText, AttributesOfTypes.Ref);
			
			Continue;
			
		EndTry;
		
		Object = AttributesOfTypes.Ref.GetObject();
		Object.Status = Status;	
		
		If Object.CheckFilling() Then
			
			Try
				
				Object.Write();
				ProcessedItemsCount = ProcessedItemsCount + 1;
				
			Except
				
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				
				ErrorTemplate = NStr("vi = 'Không thể ghi lại %1. %2';
									|ru = 'Не удалось записать %1. %2';
									|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
									|it = 'Не удалось записать %1. %2';
									|pl = 'Nie udało się zapisać %1. %2';
									|tr = '%1 kaydedilemedi. %2'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate,
					AttributesOfTypes.Presentation,
					ErrorDescription);
				Common.MessageToUser(ErrorText, AttributesOfTypes.Ref);
				
			EndTry;
			
		EndIf;
		
	EndDo;
	
	Return ProcessedItemsCount;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region MethodsForConfiguringFormFields

Procedure SettingUpFieldWithoutCalculation(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("WithoutCalculation");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	
EndProcedure

Procedure SettingUpGoodsIndicatorField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsIndicator");
	
	ConfigurationModule.NewFilter(Item.Condition, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("GoodsIndicator");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpSalesCalculationBaseField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("SalesCalculationBase");
	
	ConfigurationModule.NewFilter(Item.Condition, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("SalesCalculationBase");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpMembershipField(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("PartyList");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	
EndProcedure

Procedure SettingUpFieldSelectionOfParticipants(Settings, ConfigurationModule)
	
	LineUpsOfParticipants = Enums.RebatesParticipants;
	
	ParticipantsList = New ValueList; // ValueList of EnumRef.RebatesParticipants
	ParticipantsList.Add(LineUpsOfParticipants.Contracts);
	ParticipantsList.Add(LineUpsOfParticipants.Terms1);
	
	Item = Settings.Add();
	
	Item.Fields.Add("FilterParties");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	AndGroup = RebatesServer.NewFiltersGroup(OrGroup);
	ConfigurationModule.NewFilter(AndGroup, "PartyList", ParticipantsList,, DataCompositionComparisonType.InList);
	
	Item.Properties.Insert("ReadOnly", True);
	
EndProcedure

Procedure SettingUpGoodsCompositionField(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ContentOfGoods");
	
	ConfigurationModule.NewFilter(Item.Condition, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	
	Item = Settings.Add();
	
	Item.Fields.Add("ContentOfGoods");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpSelectionOfGoodsField(Settings, ConfigurationModule)
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	BaseOfCalculation = Enums.RebateCalculationBases;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	ConfigurationModule.NewFilter(Item.Condition, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	
	Item = Settings.Add();
	
	Item.Fields.Add("FilterOfProducts_");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "SalesCalculationBase", BaseOfCalculation.RevenueBasePrices);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(SalesFigures.NotUsed);
	ExclIndicators.Add(SalesFigures.Sum);
	ConfigurationModule.NewFilter(OrGroup, "GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.NotInList);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpConditionTimeFenceField(Settings, ConfigurationModule)
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	Item = Settings.Add();
	
	Item.Fields.Add("ConditionFrequency");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	ConfigurationModule.NewFilter(OrGroup, "GoodsIndicator", SalesFigures.NotUsed);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

Procedure SettingUpFieldThatIncludesVAT(Settings, ConfigurationModule)
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ConsiderVAT");
	
	BaseOfCalculation = Enums.RebateCalculationBases;
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	ConfigurationModule.NewFilter(OrGroup, "SalesCalculationBase", BaseOfCalculation.EmptyRef());
	ConfigurationModule.NewFilter(OrGroup, "SalesCalculationBase", BaseOfCalculation.RevenueBasePrices);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("ConsiderVAT");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpDistributionOrderField(Settings, ConfigurationModule)
	
	SalesFigures = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("AllocationProcedure");
	
	OrGroup = RebatesServer.NewFiltersGroup(Item.Condition);
	
	ExclIndicators = New ValueList; // ValueList of EnumRef.TargetSalesIndicatorsOfRebatesByGoods
	ExclIndicators.Add(SalesFigures.NotUsed);
	ExclIndicators.Add(SalesFigures.QuantityTotal);
	ConfigurationModule.NewFilter(OrGroup, "GoodsIndicator", ExclIndicators,, DataCompositionComparisonType.InList);
	ConfigurationModule.NewFilter(OrGroup, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("AllocationProcedure");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpAccrualTimeFenceField(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("AccrualFrequency");
	
	ConfigurationModule.NewFilter(Item.Condition, "WithoutCalculation", True);
	
	Item.Properties.Insert("Visible", False);
	
EndProcedure

Procedure SettingUpItemPropertyField(Settings, ConfigurationModule)
	
	GoodsCompositions = Enums.RebatesItems;
	
	#Region Visible
	Item = Settings.Add();
	
	Item.Fields.Add("ProductItemProperty");
	
	ConfigurationModule.NewFilter(Item.Condition, "ContentOfGoods", GoodsCompositions.ProductItemProperty);
	
	Item.Properties.Insert("Visible", True);
	#EndRegion
	
	#Region ReadOnly
	Item = Settings.Add();
	
	Item.Fields.Add("ProductItemProperty");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("ReadOnly", True);
	#EndRegion
	
EndProcedure

Procedure SettingUpUsageDecorationField(Settings, ConfigurationModule)
	
	Item = Settings.Add();
	
	Item.Fields.Add("DecorationIsRebateKindUsed");
	
	ConfigurationModule.NewFilter(Item.Condition, "More.RebateKindIsUsed", True);
	
	Item.Properties.Insert("Visible", True);
	
EndProcedure

#EndRegion

#Region Other

// These are the properties of the item.
// 
// Parameters:
//  DataSources - Array of CatalogRef.VendorRebateKinds
// 
// Returns:
//  ValueTable - See DataSetItemProperties
//
Function TheseArePropertiesOfNomenclature(DataSources)
	
	DataSet = DataSetItemProperties();
	ProductProperties_ = Common.ObjectsAttributeValue(DataSources, "ProductItemProperty");
	
	For Each DataSource In ProductProperties_ Do
		
		ProductItemProperty = DataSource.Value;
		DataProperty = RebatesServer.ItemPropertyVerificationData(ProductItemProperty);
		
		DataFieldsVal = DataSet.Add();
		DataFieldsVal.Ref = DataSource.Key;
		DataFieldsVal.ProductProperties_Presentation = DataProperty.Title;
		
	EndDo;
	
	Return DataSet;
	
EndFunction

// Returns:
//  ValueTable - Data Set Item Properties:
// * Ref - CatalogRef.VendorRebateKinds
// * ProductProperties_Presentation - String
//
Function DataSetItemProperties()
	
	DataSet = New ValueTable();
	DataSet.Columns.Add("Ref");
	DataSet.Columns.Add("ProductProperties_Presentation");
	
	Return DataSet;
	
EndFunction

// Selection of Attributes of types for status updates
// 
// Parameters:
//  Kinds  - Array of CatalogRef.CustomerRebatesKinds - Array of links
//  Status - EnumRef.RebatesKindsStatuses - Status
// 
// Returns:
//  QueryResultSelection - Selection Of Props Types:
//	* Presentation - String
//	* Ref - CatalogRef.CustomerRebatesKinds
//	* StatusMatches - Boolean
//	* DeletionMark - Boolean
//	* Used - Boolean - used in retro bonus terms and conditions documents
//
Function SelectionOfPropsTypes(Kinds, Status)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RebateKinds.Ref AS Ref
	|INTO UsedKinds
	|FROM
	|	Catalog.CustomerRebatesKinds AS RebateKinds
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ConditionsOfCustomerRebates AS ConditionsOfCustomerRebates
	|			WHERE
	|				ConditionsOfCustomerRebates.RebateKind = RebateKinds.Ref)
	|	AND RebateKinds.Ref IN(&Kinds)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RebateKinds.Presentation AS Presentation,
	|	RebateKinds.Ref AS Ref,
	|	CASE
	|		WHEN RebateKinds.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	RebateKinds.DeletionMark AS DeletionMark,
	|	NOT UsedKinds.Ref IS NULL AS Used
	|FROM
	|	Catalog.CustomerRebatesKinds AS RebateKinds
	|		LEFT JOIN UsedKinds AS UsedKinds
	|		ON RebateKinds.Ref = UsedKinds.Ref
	|WHERE
	|	RebateKinds.Ref IN(&Kinds)";
	
	Query.SetParameter("Kinds", Kinds);
	Query.SetParameter("Status", Status);
	Selection = Query.Execute().Select();
	
	Return Selection;
	
EndFunction

#EndRegion

#EndRegion

#EndIf