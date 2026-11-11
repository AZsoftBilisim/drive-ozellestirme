
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ClearMessages();
	IsInputAvailable = DocumentCreationIsAvailable(CommandParameter);
	
	If Not IsInputAvailable Then
		
		MessageText = NStr("vi = 'Cho phép tạo nguyên vật liệu có thể hoán đổi cho nhau chỉ đối với chế độ ""Tập hợp sang tập hợp""';
							|ru = 'Создание взаимозаменяемых аналогов доступно только для режима ""Набор на набор""';
							|en = 'You can create interchangeable substitutes only in ""Set to set"" mode'; fa = 'You can create interchangeable substitutes only in ""Set to set"" mode';
							|it = 'You can create interchangeable substitutes only in ""Set to set"" mode';
							|pl = 'You can create interchangeable substitutes only in ""Set to set"" mode';
							|tr = 'Değiştirilebilir İkamelerin oluşturulabilmesi sadece ""Kümeden Kümeye"" modunda mümkündür'");
		CommonClient.MessageToUser(MessageText);
		Return;
	
	EndIf;
	
	FilterItems1 = New Structure("DocumentPermissions, InterchangeableSubstitutes", CommandParameter, True);
	FormParameters = New Structure("FillingValues", FilterItems1);
	
	OpenForm("Document.EngineeringChangeOrder.Form.DocumentForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);

EndProcedure

#EndRegion

#Region Private

&AtServer
Function DocumentCreationIsAvailable(Resolution)

	Status = Common.ObjectAttributeValue(Resolution, "ReplacementOption");
	Return Status <> Enums.SubstituteReplacementOption.SubstituteList;

EndFunction 

#EndRegion
