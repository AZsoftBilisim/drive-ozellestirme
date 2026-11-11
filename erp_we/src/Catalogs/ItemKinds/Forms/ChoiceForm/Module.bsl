
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SeveralKindsOfProducts = GetFunctionalOption("UseMultipleKindsOfProducts");
	Items.DecorationDecodingOfSelection.Visible = False;

	If ValueIsFilled(Parameters.CurrentKind) Then
		
		CommonClientServer.SetDynamicListFilterItem(List,
																				"Ref",
																				Parameters.CurrentKind,
																				DataCompositionComparisonType.NotEqual,
																				,
																				True);
	ElsIf Parameters.Property("Products") Then
		
		CustomizeList(Parameters.Products);
		
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeList(Products = Undefined, DisablingSelection = False)
	
	ConditionsForSelectingNewTypeOfProduct = Catalogs.Products.ConditionsForSelectingNewTypeOfProduct();
	
	QueryText = 
	"SELECT
	|	ProductKindOverridable.Ref,
	|	ProductKindOverridable.DeletionMark,
	|	ProductKindOverridable.Parent,
	|	ProductKindOverridable.IsFolder,
	|	ProductKindOverridable.Description,
	|	ProductKindOverridable.AlcoholContainingProducts,
	|	ProductKindOverridable.SaleRegistrationOption,
	|	ProductKindOverridable.PresentationOptionInPrintForms,
	|	ProductKindOverridable.SetPricingOption,
	|	ProductKindOverridable.KeepRecordsByCCD,
	|	ProductKindOverridable.KeepRecordsOfQualityCertificates,
	|	ProductKindOverridable.KindOfAlcoholContainingProducts,
	|	ProductKindOverridable.BatchOwner,
	|	ProductKindOverridable.ProductCategoryOwner,
	|	ProductKindOverridable.ItemVariantsOwner,
	|	ProductKindOverridable.AnalyticalGroup,
	|	ProductKindOverridable.AccessGroup,
	|	ProductKindOverridable.FinancialAccountingGroup,
	|	ProductKindOverridable.UnitForReports,
	|	ProductKindOverridable.UnitOfMeasure,
	|	ProductKindOverridable.RestrictNameChangeToPrintItems,
	|	ProductKindOverridable.DisableNameChangeToPrintItemVariant,
	|	ProductKindOverridable.ProhibitEditingWorkingTitleOfItems,
	|	ProductKindOverridable.ProhibitEditingWorkingTitleOfItemVariants,
	|	ProductKindOverridable.ImportedAlcoholContainingProducts,
	|	ProductKindOverridable.UseVariants,
	|	ProductKindOverridable.UseCustomNameForPrinting,
	|	ProductKindOverridable.SpecifyQuantityWhenRegisteringBatch,
	|	ProductKindOverridable.SpecifyNumberWhenRegisteringBatch,
	|	ProductKindOverridable.KeepAccountingByBatch,
	|	ProductKindOverridable.UseShelfLifeOnBatchRegistration,
	|	ProductKindOverridable.UsePackages,
	|	ProductKindOverridable.UseCharacteristics,
	|	ProductKindOverridable.ControlUniquenessOfItems,
	|	ProductKindOverridable.ControlUniquenessOfItemVariants,
	|	ProductKindOverridable.UnitFactorForReports,
	|	ProductKindOverridable.PropertiesSet,
	|	ProductKindOverridable.BatchPropertySet,
	|	ProductKindOverridable.CharacteristicsPropertySet,
	|	ProductKindOverridable.PackagingGroup,
	|	ProductKindOverridable.NameForPrinting,
	|	ProductKindOverridable.BatchUsageSettings,
	|	ProductKindOverridable.ReusablePackageItems,
	|	ProductKindOverridable.AssignedPurchaseSale,
	|	ProductKindOverridable.BatchSettingsAreTakenFromOtherItemsKind,
	|	ProductKindOverridable.LongDesc,
	|	ProductKindOverridable.AccountingFeature,
	|	ProductKindOverridable.SuppliedInReusablePackage,
	|	ProductKindOverridable.ItemsGroup,
	|	ProductKindOverridable.BatchAccountingPolicy,
	|	ProductKindOverridable.WarehouseGroup,
	|	ProductKindOverridable.ContainsPreciousMetalsOrStones,
	|	ProductKindOverridable.ItemsType,
	|	ProductKindOverridable.PrecisionOfBatchShelfLifeIndication,
	|	ProductKindOverridable.ReusablePackageVariant,
	|	ProductKindOverridable.ProductCategoriesCommonWithAnotherKindOfItems,
	|	ProductKindOverridable.NameTemplateForPrintingOfProductItem,
	|	ProductKindOverridable.NameTemplateForPrintingCharacteristics,
	|	ProductKindOverridable.WorkingNameTemplateOfProductItem,
	|	ProductKindOverridable.WorkingNameTemplateSetOfSeries,
	|	ProductKindOverridable.WorkingNameTemplateCharacteristics,
	|	ProductKindOverridable.PriceTagTemplate,
	|	ProductKindOverridable.LabelsTemplate,
	|	ProductKindOverridable.LabelTemplateBatches,
	|	ProductKindOverridable.BusinessActivityClassifierCode,
	|	ProductKindOverridable.FEACNCode,
	|	ProductKindOverridable.Presentation
	|FROM
	|	Catalog.ItemKinds AS ProductKindOverridable";
	
	If Not ValueIsFilled(Products)
		Or DisablingSelection Then
		
		SetListProperties(QueryText);
		
		Items.DecorationDecodingOfSelection.Visible = False;
		
		Return;
		
	EndIf;
	
	QueryText = QueryText + "
	|WHERE
	|	ProductKindOverridable.IsFolder
	|	OR TRUE ";
	
	For Each KeyValue In ConditionsForSelectingNewTypeOfProduct Do
		
		ParameterText1 = StrReplace(KeyValue.Value, "NewTypeOfProduct", "ProductKindOverridable");
		QueryText = QueryText + " AND NOT " + ParameterText1;
		
	EndDo;
	
	Query = New Query;
	Query.Text = QueryText;
	QueryOptions = Query.FindParameters();

	AttributesNames = New Structure;
	For Each Parameter In QueryOptions Do
		AttributesNames.Insert(Parameter.Name, "ProductKind." + Parameter.Name);
	EndDo;
	
	OldDetails = Common.ObjectAttributesValues(Products, AttributesNames);
	
	SetListProperties(QueryText);
	
	For Each Parameter In QueryOptions Do
		CommonClientServer.SetDynamicListParameter(List,
																			Parameter.Name,
																			OldDetails[Parameter.Name],
																			True);
	EndDo;
	
	Items.List.Refresh();
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Nếu mặt hàng đã được sử dụng trong chương trình (trong các chứng từ, tùy chỉnh...) thì khi thay đổi tùy ý dạng mặt hàng sẽ dẫn đến lỗi. Các dạng mặt hàng được hiển thị và có thể chọn mà không gây ra bất kỳ lỗi nào.';
						|ru = 'Если номенклатура уже была задействована в программе (в документах, настройках и т.п.), то произвольное изменение вида номенклатуры может привести к проблемам. Показаны виды номенклатуры, которые можно выбрать без привнесения проблем.';
						|en = 'If an item is already used in the application (documents, settings, etc.), arbitrary change of item kind may cause problems. Item kinds which can be selected without causing any issues are now displayed.'; fa = 'If an item is already used in the application (documents, settings, etc.), arbitrary change of item kind may cause problems. Item kinds which can be selected without causing any issues are now displayed.';
						|it = 'Se l''articolo è già stato coinvolto nel programma (in documenti, impostazioni, ecc.), allora una modifica arbitraria del tipo di articolo potrebbe causare problemi. Sono indicati i tipi di articolo che si possono scegliere senza introdurre problemi.';
						|pl = 'Jeśli towar był już użyty w programie (w dokumentach, ustawieniach itp.), to dowolna zmiana rodzaju towaru może spowodować problemy. Przedstawiono rodzaje nomenklatury, które można wybrać, nie powodując problemów.';
						|tr = 'Öğe, programa (belgelere, ayarlara vb.) zaten dahil edilmişse, öğe türünde serbest bir değişiklik sorunlara yol açabilir. Sorun çıkarmadan seçilebilecek öğe türleri gösterilmiştir.'"));	
	
	If Users.RolesAvailable("EditObjectAttributes") Then
		PartOfFormattedString = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = '<a href=""%1"">Hiển thị tất cả dạng mặt hàng</a>.';
											|ru = '<a href=""%1"">Показать все виды номенклатуры</a>.';
											|en = '<a href=""%1"">Show all item kinds</a>.'; fa = '<a href=""%1"">Show all item kinds</a>.';
											|it = '<a href=""%1"">Show all item kinds</a>.';
											|pl = '<a href=""%1"">Show all item kinds</a>.';
											|tr = '<a href=""%1"">Tüm öğe türlerini göster</a>.'"),
										"ClearFilter");
		RowsArray.Add(PartOfFormattedString);
	EndIf;
	
	Items.DecorationDecodingOfSelection.Visible = True;
	Items.DecorationDecodingOfSelection.Title = StringFunctions.FormattedString(
														StrConcat(RowsArray, " "));
	
EndProcedure

&AtServer
Procedure SetListProperties(QueryText)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText					= QueryText;
	ListProperties.MainTable				= "Catalog.ItemKinds";
	ListProperties.DynamicDataRead	= True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtClient
Procedure DecorationDecodingOfSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	StandardProcessing = False;
	
	If Var_URL = "ClearFilter" Then 
		CustomizeList(,True);
	EndIf;
EndProcedure

#EndRegion

#Region AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
