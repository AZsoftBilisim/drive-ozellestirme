
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	Items.DecorationDecodingOfSelection.Visible = False;

	If ValueIsFilled(Parameters.CurrentKind) Then

		CommonClientServer.SetDynamicListFilterItem(List, "Ref", Parameters.CurrentKind,
			DataCompositionComparisonType.NotEqual, , True);
	ElsIf Parameters.Property("Incident") Then

		CustomizeList(Parameters.CurrentRow);

	EndIf;

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeList(IncidentKind = Undefined, DisablingSelection = False)

	Items.List.Refresh();

	If Not ValueIsFilled(IncidentKind) Or DisablingSelection Then

		CommonClientServer.DeleteDynamicListFilterGroupItems(List, "Ref");
		Items.DecorationDecodingOfSelection.Visible = False;

		Return;

	EndIf;

	PropertiesSet = Common.ObjectAttributeValue(IncidentKind, "PropertiesSet");

	LimitingChoiceOfTypeOfIncidents = Catalogs.Incidents.RestrictingSelectionOfNewTypeOfIncident(PropertiesSet);

	If LimitingChoiceOfTypeOfIncidents Then
		
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", IncidentKind,
			DataCompositionComparisonType.Equal, , True);

		MessageText = (NStr(
			"vi = 'Nếu xảy ra sự cố khi làm việc thì việc thay đổi tùy ý dạng sự cố có thể dẫn đến lỗi. Hiển thị các dạng sự cố có thể chọn mà không gây ra lỗi.';
			|ru = 'Если инцидент уже в работе, то произвольное изменение вида инцидента может привести к проблемам. Показаны виды инцидентов, которые можно выбрать без привнесения проблем.';
			|en = 'If an incident is already under review, changes to an incident kind might lead to issues. On the screen, you can see incident kinds that you can select without causing issues.'; fa = 'If an incident is already under review, changes to an incident kind might lead to issues. On the screen, you can see incident kinds that you can select without causing issues.';
			|it = 'Se l''incidente viene già elaborato, la modifica libera del tipo di incidente può causare problemi. Sono mostrati i tipi di incidenti che posso essere scelti senza causare problemi.';
			|pl = 'Jeśli incydent jest już w pracy, to dowolna zmiana rodzaju incydentu może spowodować problemy. Są pokazane rodzaje incydentów, które można wybrać bez wnoszenia problemów.';
			|tr = 'Bir olay zaten devam ediyorsa, olayın türünü keyfi olarak değiştirmek sorunlara yol açabilir. Sorun yaratmadan seçilebilecek olay türleri gösterilmektedir.'"));

		If Users.RolesAvailable("EditObjectAttributes") Then
			NameOfNavigationLink = "ClearFilter";
			MessageText = StrTemplate(NStr(
				"vi = 'Nếu xảy ra sự cố khi làm việc thì việc thay đổi tùy ý dạng sự cố có thể dẫn đến lỗi. Hiển thị các dạng sự cố có thể chọn mà không gây ra lỗi. <a href=""%1"">Hiển thị tất cả dạng sự cố.</a>';
				|ru = 'Если инцидент уже в работе, то произвольное изменение вида инцидента может привести к проблемам. Показаны виды инцидентов, которые можно выбрать без привнесения проблем. <a href=""%1"">Показать все виды инцидентов.</a>';
				|en = 'If an incident is already under review, changes to an incident kind might lead to issues. You can see the incident kinds that you can select without causing issues. <a href=""%1"">Show all incident kinds.</a>'; fa = 'If an incident is already under review, changes to an incident kind might lead to issues. You can see the incident kinds that you can select without causing issues. <a href=""%1"">Show all incident kinds.</a>';
				|it = 'Если инцидент уже в работе, то произвольное изменение вида инцидента может привести к проблемам. Показаны виды инцидентов, которые можно выбрать без привнесения проблем. <a href=""%1"">Показать все виды инцидентов.</a>';
				|pl = 'If an incident is already under review, changes to an incident kind might lead to issues. You can see the incident kinds that you can select without causing issues. <a href=""%1"">Show all incident kinds.</a>';
				|tr = 'Bir olay zaten devam ediyorsa, olayın türünü keyfi olarak değiştirmek sorunlara yol açabilir. Sorun yaratmadan seçilebilecek olay türleri gösterilmektedir. <a href=""%1"">Tüm olay türlerini göster.</a>'"), NameOfNavigationLink);
		EndIf;

		Items.DecorationDecodingOfSelection.Visible = True;

		Items.DecorationDecodingOfSelection.Title = StringFunctions.FormattedString(MessageText);

	EndIf;

EndProcedure

&AtClient
Procedure DecorationDecodingOfSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "ClearFilter" Then 
		CustomizeList(,True);
	EndIf;
	
EndProcedure

#EndRegion
