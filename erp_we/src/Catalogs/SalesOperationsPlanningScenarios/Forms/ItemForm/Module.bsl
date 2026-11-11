
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If Not GetFunctionalOption("EnterpriseManagement") Then
		
		Items.UseForMaterialsPlanning.Title = NStr("vi = 'Tính toán yêu cầu đối với nguyên vật liệu và nguồn lao động';
													|ru = 'Расчет потребностей в материалах и трудовых ресурсах';
													|en = 'Calculation of demand for materials and human resources'; fa = 'Calculation of demand for materials and human resources';
													|it = 'Calcolo del bisogno in materiali e risorse di lavoro';
													|pl = 'Obliczanie zapotrzebowania na materiały i siłę roboczą';
													|tr = 'Materyallerde hesaplama ihtiyacı ve iş kaynakları'");
		
		Items.Calendar.ToolTip = NStr("vi = 'Lịch làm việc được sử dụng để tính ngày khởi động sản phẩm, cũng như thời gian yêu cầu nguyên vật liệu và lao động';
										|ru = 'Календарь работы, используемый для расчета дат запуска продукции, а так же сроков потребностей в материалах и трудовых ресурсах';
										|en = 'Work calendar used to calculate product launch dates as well as dates of demand for materials and human resources'; fa = 'Work calendar used to calculate product launch dates as well as dates of demand for materials and human resources';
										|it = 'Calendario di lavoro utilizzato per il calcolo delle date di avvio di produzione, oltre alle tempistiche dei bisogni in materiali e risorse di lavoro.';
										|pl = 'Kalendarz pracy, używany do obliczania dat uruchomienia produkcji, a także okresów zapotrzebowania na materiały i siłę roboczą';
										|tr = 'İş takvimi, ürünlerin giriş tarihi hesaplaması için kullanılabileceği gibi materyallerdeki ihtiyaçlarda ve iş kaynaklarında da kullanılabilir'");
		
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
						
EndProcedure
 
&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	PurchasePlanPlan = ?(Object.CreatePurchasePlanByAmount, 1, 0);
	SalesPlanPlan = ?(Object.CreateSalesPlanByAmount, 1, 0);
	
	DisplayPeriod = ?(Object.ShowNumberOfPeriod, 1, 0);
	
	CommonClientServer.SetDynamicListFilterItem(
			PlansStructure,
			"Owner",
			Object.Ref,
			DataCompositionComparisonType.Equal,
			StrTemplate(NStr("vi = '%1';
							|ru = '%1';
							|en = '%1'; fa = '%1';
							|it = '%1';
							|pl = '%1';
							|tr = '%1'"), "FilterByOwner"),
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	CommonClientServer.SetDynamicListParameter(PlansStructure, "PlanningProcessManagement", Object.PlanningProcessManagement);
	
	SetItemsVisibility();
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure 

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	CommonClientServer.SetDynamicListFilterItem(
			PlansStructure,
			"Owner",
			Object.Ref,
			DataCompositionComparisonType.Equal,
			StrTemplate(NStr("vi = '%1';
							|ru = '%1';
							|en = '%1'; fa = '%1';
							|it = '%1';
							|pl = '%1';
							|tr = '%1'"), "FilterByOwner"),
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PlanForChanges(Item)
	
	Object.CreatePurchasePlanByAmount = PurchasePlanPlan = 1;
	Object.CreateSalesPlanByAmount = SalesPlanPlan = 1;
	If Not (Object.CreatePurchasePlanByAmount Or Object.CreateSalesPlanByAmount)Then
		Object.Currency = Undefined;
	EndIf; 
	ConfigureDependentFormElements(ThisForm, "PurchasePlanPlan, SalesPlanPlan");
	
EndProcedure

&AtClient
Procedure PeriodicityOnChange(Item)
	
	If Object.Periodicity = PredefinedValue("Enum.Periodicity.Year")
		Or Object.Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
	
		Object.ShowNumberOfPeriod = False;
		DisplayPeriod = 0;
	
	EndIf; 
	ConfigureDependentFormElements(ThisForm, "Periodicity");
	
EndProcedure

&AtClient
Procedure DisplayPeriodOnChange(Item)
	
	Object.ShowNumberOfPeriod = DisplayPeriod = 1;
	
EndProcedure

&AtClient
Procedure UseForMaterialsPlanningOnChange(Item)
	
	If Object.UseForMaterialsPlanning Then
		Object.DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.PossibleConsumption");
	Else
		Object.Calendar = Undefined;
		Object.DemandForMaterials = Undefined;
	EndIf;
	
	ConfigureDependentFormElements(
		ThisForm,
		"UseForMaterialsPlanning, DemandForMaterials");

EndProcedure

&AtClient
Procedure RecordedInBudgetingOnChange(Item)
	If Not Object.RecordedInBudgeting Then
		Object.BudgetingScenario = Undefined
	EndIf;
	ConfigureDependentFormElements(ThisForm, "RecordedInBudgeting");
	Return // In UT 11.1, the code of this handler is empty
	
EndProcedure

&AtClient
Procedure BudgetingScenarioStartChoice(Item, ChoiceData, StandardProcessing)
	ParametersArray = New Array;
	
	If ValueIsFilled(Object.Currency) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Currency", Object.Currency));
	EndIf;
	
	If ValueIsFilled(Object.Periodicity) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Periodicity", Object.Periodicity));
	EndIf;
	
	ParametersArray.Add(New ChoiceParameter("Filter.Predefined", False));
	
	FixedArrayOfParameters = New FixedArray(ParametersArray);
	Items.BudgetingScenario.ChoiceParameters = FixedArrayOfParameters;
	Return // In UT 11.1, the code of this handler is empty
	
EndProcedure 

&AtClient
Procedure DemandForMaterialsOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "DemandForMaterials");
	
EndProcedure

&AtClient
Procedure PlanningProcessManagementOnChange(Item)
	CommonClientServer.SetDynamicListParameter(PlansStructure, "PlanningProcessManagement", Object.PlanningProcessManagement);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	UsePurchasePlanning = GetFunctionalOption("UsePurchasePlanning");
	UseSalesPlans = GetFunctionalOption("UseSalesPlans");
	UseAssemblyDisassemblyPlanning = GetFunctionalOption("UseAssemblyDisassemblyPlanning");
	UsePlanningOfInventoryConsumption = GetFunctionalOption("UsePlanningOfInventoryConsumption");
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UseAssemblyDisassemblyOrders = GetFunctionalOption("UseAssemblyDisassemblyOrders");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	Items.PlanningGroup.Visible = (UsePurchasePlanning Or UseSalesPlans);
	
	Items.GroupUseCalculationBySalesSpeed.Visible = GetFunctionalOption("UseSalesRanks")
		And GetFunctionalOption("UseProductCategories")
		And GetFunctionalOption("UseSalesPlansByCategories");
		
	UseProductionPlanning = False;
	UseProductionPlanning = GetFunctionalOption("UseProductionPlanning");
	AvailableDescriptionOfProbabilityOfApplicationOfMaterials = False;
	AvailableDescriptionOfProbabilityOfApplicationOfMaterials = ProductDataManagement.AvailableDescriptionOfProbabilityOfApplicationOfMaterials();
	Items.UseMaterialPlansGroup.Visible = UseProductionPlanning;
	Items.GroupMethodForCalculatingMaterialRequirements.Visible = UseProductionPlanning And AvailableDescriptionOfProbabilityOfApplicationOfMaterials;
	RightToViewBudgetItems = AccessRight("View", Metadata.Catalogs.BudgetFlowItems);
	Items.GroupReflectInBudgeting.Visible = RightToViewBudgetItems;
	Items.GroupReflectInBudgeting.Visible = Not GetFunctionalOption("TradeManagement");
	
	Items.PlanningByAssignments.Visible = UseOrderSupplyWithAssignment;

	Items.PlansStructureCreateStage.Enabled = AccessRight("Update", Metadata.Catalogs.PlanProfiles);
	
EndProcedure 

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
		
	If AttributesStructure1.Property("PurchasePlanPlan")
		Or AttributesStructure1.Property("SalesPlanPlan")
		Or Initialize Then
		
		Items.Currency.Enabled = (Object.CreatePurchasePlanByAmount Or Object.CreateSalesPlanByAmount);
		
	EndIf;
	
	If AttributesStructure1.Property("UseForMaterialsPlanning")
		Or Initialize Then
		
		Items.DemandForMaterials.Enabled = Object.UseForMaterialsPlanning;
		Items.DemandForMaterials.AutoMarkIncomplete = Object.UseForMaterialsPlanning;
		Items.Calendar.Enabled = Object.UseForMaterialsPlanning;
		
	EndIf;
	
	If AttributesStructure1.Property("DemandForMaterials")
		Or Initialize Then
		
		ToolTipText = "";
		If Object.DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.EmptyRef") Then
			ToolTipText = "";
		ElsIf Object.DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.PossibleConsumption") Then
			ToolTipText = NStr("vi = 'Dự tính nguyên vật liệu chính và nguyên vật liệu thay thế có điều chỉnh theo khả năng sử dụng.';
								|ru = 'Основные и альтернативные материалы планируются с поправкой на вероятность применения.';
								|en = 'Main and alternate materials are planned depending on use probability.'; fa = 'Main and alternate materials are planned depending on use probability.';
								|it = 'Sono previsti materiali di base e alternativi in base alla possibilità di utilizzo.';
								|pl = 'Podstawowe i alternatywne materiały są planowane z uwzględnieniem prawdopodobieństwa zastosowania.';
								|tr = 'Ana ve alternatif materyaller uygulanma olasılığı göz önünde bulundurularak planlanır.'");
		ElsIf Object.DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.MaximumConsumption") Then
			ToolTipText = NStr("vi = 'Vật liệu chính được lên kế hoạch mà không cần điều chỉnh cho xác suất ứng dụng, nguyên vật liệu thay thế được điều chỉnh cho xác suất.';
								|ru = 'Основные материалы планируются без поправки на вероятность применения, альтернативные с поправкой на вероятность.';
								|en = 'Main materials are planned regardless of use probability, and alternate materials are planned depending on use probability.'; fa = 'مواد اصلی صرف‌نظر از احتمال استفاده برنامه‌ریزی می‌شوند و مواد جایگزین بسته به احتمال استفاده برنامه‌ریزی می‌شوند.';
								|it = 'Materiali principali sono pianificati senza considerare la probabilità d''uso, quelli alternativi considerando la probabilità d''uso.';
								|pl = 'Podstawowe materiały są planowane bez uwzględnienia prawdopodobieństwa zastosowania, alternatywne z uwzględnieniem prawdopodobieństwa.';
								|tr = 'Ana malzemeler değiştirme olasılığını düzeltmeden planlanır, alternatifler ise düzeltme olasılığı ile.'");
		ElsIf Object.DemandForMaterials = PredefinedValue("Enum.MaterialCalculationMethods.MinimumConsumption") Then
			ToolTipText = NStr("vi = 'Vật liệu chính được lên kế hoạch mà không cần điều chỉnh cho khả năng sử dụng, vật liệu thay thế không được lên kế hoạch.';
								|ru = 'Основные материалы планируются без поправки на вероятность применения, альтернативные материалы не планируются.';
								|en = 'Main materials are planned regardless of use probability, and alternate materials are not planned.'; fa = 'Main materials are planned regardless of use probability, and alternate materials are not planned.';
								|it = 'I materiali di base sono pianificati senza modifiche in merito alla probabilità di utilizzo, i materiali alternativi non sono pianificati.';
								|pl = 'Podstawowe materiały są planowane bez uwzględnienia prawdopodobieństwa zastosowania, alternatywne materiały nie są planowane.';
								|tr = 'Temel materyaller, kullanım olasılığına göre ayarlanmadan planlandı, alternatif materyaller planlanmadı.'");
		EndIf;
		Items.GroupMethodForCalculatingMaterialRequirementsHint.ToolTip = ToolTipText;
		
	EndIf;
	
	If AttributesStructure1.Property("RecordedInBudgeting")
		Or Initialize Then
		
		Items.BudgetingScenario.Enabled = Object.RecordedInBudgeting;
		Items.BudgetingScenario.AutoMarkIncomplete = Object.RecordedInBudgeting;
		
	EndIf;
	If AttributesStructure1.Property("Periodicity")
		Or Initialize Then
		
		If Object.Periodicity = PredefinedValue("Enum.Periodicity.Year")
			Or Object.Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
	        Items.DisplayPeriod.Enabled = False;
		Else
			Items.DisplayPeriod.Enabled = True;
		EndIf;
		
	EndIf;
	
EndProcedure

#Region PlansStructure

&AtClient
Procedure CreateStage(Command)
	
	If Not CheckWriteScript() Then
		Return;
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Owner", Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	FormParameters.Insert("IsFolder", True);
	OpenForm("Catalog.PlanProfiles.FolderForm", FormParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure IncreasePriority(Command)
	
	MoveElement(Items.PlansStructure.CurrentRow, True);
	Items.PlansStructure.Refresh()
	
EndProcedure

&AtClient
Procedure DecreasePriority(Command)
	
	MoveElement(Items.PlansStructure.CurrentRow, False);
	Items.PlansStructure.Refresh()
	
EndProcedure

&AtServer
Procedure MoveElement(ObjectReference, Up)
	
	If ObjectReference = Undefined Then
		
		Return;
		
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	T.Ref AS Ref,
	|	CASE WHEN &Up THEN
	|		-T.PlanningProcedure
	|	ELSE
	|		T.PlanningProcedure
	|	END AS PlanningProcedure
	|FROM
	|	Catalog.PlanProfiles AS T
	|
	|WHERE
	|	CASE WHEN &Up THEN
	|		T.PlanningProcedure < &PlanningProcedure
	|	ELSE
	|		T.PlanningProcedure > &PlanningProcedure
	|	END
	|	AND T.Owner = &Scenario
	|	AND T.Parent = &Parent
	|
	|ORDER BY
	|	PlanningProcedure");
	
	Query.SetParameter("Up", Up);
	Query.SetParameter("Scenario", Object.Ref);
	StructureOfPlanViewParameters = Common.ObjectAttributesValues(ObjectReference, "PlanningProcedure, Parent");
	Query.SetParameter("PlanningProcedure", StructureOfPlanViewParameters.PlanningProcedure);
	Query.SetParameter("Parent", StructureOfPlanViewParameters.Parent);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	If Selection.Count() <> 1 Then
		
		Return;
		
	EndIf;
	
	Selection.Next();
	
	BeginTransaction();

	Try
		
		LockDataForEdit(ObjectReference);
		LockDataForEdit(Selection.Ref);
		
		ItemToMove = ObjectReference.GetObject(); // CatalogObject.PlanProfiles - 
		AdjacentElement = Selection.Ref.GetObject(); // CatalogObject.PlanProfiles - 
		
		If ItemToMove.PlanningProcedure = 0
			Or AdjacentElement.PlanningProcedure = 0 Then
			RollbackTransaction();
			Return;
		EndIf;
		
		ItemToMove.PlanningProcedure = ItemToMove.PlanningProcedure + AdjacentElement.PlanningProcedure;
		AdjacentElement.PlanningProcedure     = ItemToMove.PlanningProcedure - AdjacentElement.PlanningProcedure;
		ItemToMove.PlanningProcedure = ItemToMove.PlanningProcedure - AdjacentElement.PlanningProcedure;
	
		SetPrivilegedMode(True);
	
		ItemToMove.Write();
		AdjacentElement.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure PlansStructureBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not CheckWriteScript() Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Function CheckWriteScript()
	
	If Not ValueIsFilled(Object.Ref) Then
		
		Notification = New CallbackDescription("CheckWriteScriptCompletion", ThisObject);
		QueryText = NStr("vi = 'Để thiết lập dạng kế hoạch, cần ghi lại kịch bản. Ghi lại?';
						|ru = 'Для настройки вида плана необходимо записать сценарий. Записать?';
						|en = 'You need to record the scenario to configure the plan profile. Continue?'; fa = 'You need to record the scenario to configure the plan profile. Continue?';
						|it = 'Per l''impostazione del tipo di piano è necessario registrare lo script. Registrare?';
						|pl = 'Dla ustawienia rodzaju planu należy zapisać scenariusz. Zapisać?';
						|tr = 'Plan profilini ayarlamak için betik dosyası olarak kaydetmeniz gerekmektedir. Kaydedilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Ghi lại và tiếp tục';
												|ru = 'Записать и продолжить';
												|en = 'Save and continue'; fa = 'Save and continue';
												|it = 'Registrare e continuare';
												|pl = 'Zapisz i kontynuuj';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		ShowQueryBox(Notification, QueryText, Buttons);
		Return False;
	
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure CheckWriteScriptCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		Write();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion



