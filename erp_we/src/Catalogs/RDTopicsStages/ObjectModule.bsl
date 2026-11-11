
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	PerformCompletionCheckInElementHierarchy(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure PerformCompletionCheckInElementHierarchy(Object, Cancel)
	
	If Not Object.Parent.IsEmpty() Then
		ParentAttributes = Common.ObjectAttributesValues(Object.Parent, "Completed");
		If ParentAttributes.Completed = True And Object.Completed = False Then
			Cancel = True;
			Text = NStr("vi = 'Cần bỏ dấu ""Đã hoàn thành"" của phần tử lớp trên.';
						|ru = 'Необходимо снять признак ""Завершен"" у родительского элемента.';
						|en = 'Please, remove ""Completed"" flag from the parent item.'; fa = 'Please, remove ""Completed"" flag from the parent item.';
						|it = 'È necessario rimuovere l''indicazione ""Completato"" dell''elemento genitore.';
						|pl = 'Należy wyłączyć oznakę ""Zakończony"" dla elementu nadrzędnego.';
						|tr = 'Üst öğeden ""Tamamlandı"" işaretini kaldırın.'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"Completed",
				,
				Cancel);
		EndIf;
	EndIf;
	
	If Not Object.IsNew() And Object.Completed Then

		Query = New Query;
		Query.Text =
			"SELECT
			|	RDTopicsStages.Ref
			|FROM
			|	Catalog.RDTopicsStages AS RDTopicsStages
			|WHERE
			|	RDTopicsStages.Completed = FALSE
			|	AND RDTopicsStages.Parent IN HIERARCHY (&Ref)";
		
		Query.SetParameter("Ref", Object.Ref);
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			Cancel = True;
			Text = NStr("vi = 'Trước khi thiết lập dấu hiệu ""Đã hoàn thành"" trong phần tử hiện tại, cần đặt dấu đó trong các phần tử trực thuộc.';
						|ru = 'Перед установкой признака ""Завершен"" у текущего элемента, необходимо его установить для подчиненных элементов.';
						|en = 'Before setting the “Completed” flag for the current item, set it for subordinate items.'; fa = 'Before setting the “Completed” flag for the current item, set it for subordinate items.';
						|it = 'Prima di impostare l''indicazione ""Completato"" per l''elemento corrente, è necessario impostarlo per gli elementi subordinati.';
						|pl = 'Przed włączeniem oznaki ""Zakończony dla bieżącego elementu, należy ją włączyć dla elementów podrzędnych.';
						|tr = 'Geçerli öğe için ""Tamamlandı"" işaretini ayarlamadan önce, alt öğeler için ayarlamak gerekmektedir.'");
			Common.MessageToUser(
				Text,
				ThisObject,
				"Completed",
				,
				Cancel);
		EndIf;

	EndIf;
	
EndProcedure

#EndRegion

#EndIf