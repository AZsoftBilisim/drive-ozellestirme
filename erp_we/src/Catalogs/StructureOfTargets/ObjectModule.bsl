#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	ItemOrderSetup.FillOrderingAttributeValue(ThisObject, Cancel);
	PropsForHierarchicalOrdering = PropsForHierarchicalOrdering();
	If AttributeOfAdditionalSortingHierarchical <> PropsForHierarchicalOrdering Then
		AttributeOfAdditionalSortingHierarchical = PropsForHierarchicalOrdering;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Let's clear the cache of calculated values of the analysis variant, 
	// because the structure of the calculated stored data depends on its settings.
	AnalysisOptionsForSourceCleanup = OptionsForGoalAnalysis(Ref);
	
	If Not AnalysisOptionsForSourceCleanup = Undefined Then
		RecordSet = InformationRegisters.DataSourcesOfTargetValueAnalysisOptions.CreateRecordSet();
		While AnalysisOptionsForSourceCleanup.Next() Do 
			RecordSet.Filter.AnalysisOption.Set(AnalysisOptionsForSourceCleanup.AnalysisOption);
			RecordSet.Write();
			
		EndDo;
		
	EndIf;
	
	UpdateHierarchicalOrderingProps(Ref, AttributeOfAdditionalSortingHierarchical);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not MeasurableTarget Then
		 NotCheckedAttributeArray.Add("TargetValue");
		 NotCheckedAttributeArray.Add("ShortNameOfTargetValue");
		 NotCheckedAttributeArray.Add("TargetTrend");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Function PropsForHierarchicalOrdering()
	
	PropsForHierarchicalOrdering = Format(AddlOrderingAttribute, "ND=5; NZ=; NLZ=; NG=");
	CheckedParent = Parent;
	If ValueIsFilled(CheckedParent) Then
		ParentPropsValues = Common.ObjectAttributeValue(CheckedParent, "AttributeOfAdditionalSortingHierarchical");
		PropsForHierarchicalOrdering = ParentPropsValues + PropsForHierarchicalOrdering;
	EndIf;
	
	Return PropsForHierarchicalOrdering;
	
EndFunction

Procedure UpdateHierarchicalOrderingProps(Var_Ref, PropsForHierarchicalOrdering)
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	StructureOfTargets.Ref
	|FROM
	|	Catalog.StructureOfTargets AS StructureOfTargets
	|WHERE
	|	StructureOfTargets.Parent = &Ref
	|	AND NOT StructureOfTargets.AttributeOfAdditionalSortingHierarchical LIKE &PropsForHierarchicalOrdering";
	
	Query.SetParameter("Ref", Var_Ref);
	Query.SetParameter("PropsForHierarchicalOrdering", PropsForHierarchicalOrdering + "%");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		While Selection.Next() Do
			ObjectToChange = Selection.Ref.GetObject();
			Try 
				ObjectToChange.Lock();
			Except
				TextOfRecordException = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay đổi tùy chỉnh đặt trình tự đối với phần tử cấu trúc mục tiêu ""%1"" 
				|Có thể là phần tử cấu trúc mục tiêu đang được chỉnh sửa bởi người sử dụng khác';
				|ru = 'Не удалось изменить настройку упорядочивания для элемента структуры целей ""%1"" 
				|Возможно, элемент структуры целей редактируется другим пользователем';
				|en = 'Cannot change the arrangement setting for the ""%1""goal tree item 
				|Perhaps, the purpose structure item is being edited by another user'; fa = 'Cannot change the arrangement setting for the ""%1""goal tree item 
				|Perhaps, the purpose structure item is being edited by another user';
				|it = 'Non è stato possibile modificare la configurazione della regolazione per le categorie degli obiettivi ""%1"" 
				|Probabilmente, la categoria degli obiettivi sta venendo modificata da un altro utente';
				|pl = 'Zmiana ustawień porządkowania elementu struktury celów ""%1"" nie powiodła się 
				|Być może element struktury celów jest edytowany przez innego użytkownika';
				|tr = 'Hedef yapı öğesi için sıralama ayarı değiştirilemedi ""%1"" 
				|Belki de hedef yapı öğesi başka bir kullanıcı tarafından düzenleniyordur'"),
				ObjectToChange.Description);
				Raise TextOfRecordException;
			EndTry;
			ObjectToChange.Write();
		EndDo;
	EndIf;
	
EndProcedure

Function OptionsForGoalAnalysis(Target)
	
	Query = New Query;
	Query.SetParameter("Target", Target);
	Query.Text = "SELECT
	               |	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption
	               |FROM
	               |	InformationRegister.DataSourcesOfTargetValueAnalysisOptions AS DataSourcesOfTargetValueAnalysisOptions
	               |WHERE
	               |	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption.Owner = &Target
	               |
	               |GROUP BY
	               |	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption";
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return QueryResult.Select();
		
	Else
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf