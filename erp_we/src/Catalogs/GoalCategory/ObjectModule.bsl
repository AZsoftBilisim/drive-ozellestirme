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
	
	UpdateHierarchicalOrderingProps(Ref, AttributeOfAdditionalSortingHierarchical);
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
	|	GoalCategory.Ref
	|FROM
	|	Catalog.GoalCategory AS GoalCategory
	|WHERE
	|	GoalCategory.Parent = &Ref
	|	AND NOT GoalCategory.AttributeOfAdditionalSortingHierarchical LIKE &PropsForHierarchicalOrdering";
	
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
				NStr("vi = 'Không thể thay đổi tùy chỉnh đặt trình tự đối với thể loại mục tiêu ""%1"" 
				|Có thể, là thể loại mục tiêu do người sử dụng khác soạn';
				|ru = 'Не удалось изменить настройку упорядочивания для категории целей ""%1"" 
				|Возможно, категория целей редактируется другим пользователем';
				|en = 'Cannot change the arrangement setting for the ""%1"" target category
				|Perhaps, the target category is being edited by another user'; fa = 'Cannot change the arrangement setting for the ""%1"" target category
				|Perhaps, the target category is being edited by another user';
				|it = 'Non è stato possibile modificare la configurazione della regolazione per le categorie degli obiettivi ""%1"" 
				|Probabilmente, la categoria degli obiettivi sta venendo modificata da un altro utente';
				|pl = 'Zmiana ustawień porządkowania dla kategorii celów ""%1"" 
				| nie powiodła się. Być może kategoria celów jest edytowana przez innego użytkownika';
				|tr = 'Hedef kategorileri için sıralama ayarları değiştirilemedi ""%1"" 
				|Hedef kategorisi başka kullanıcı tarafından düzenleniyor olabilir'"),
				ObjectToChange.Description);
				Raise TextOfRecordException;
			EndTry;
			ObjectToChange.Write();
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf