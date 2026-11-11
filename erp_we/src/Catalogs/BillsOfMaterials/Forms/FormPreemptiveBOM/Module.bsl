
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	CallParameters = Catalogs.BillsOfMaterials.ListOfPreemptiveSpecificationsCallParameters(Parameters.Context);
	
	Title = StrTemplate(NStr("vi = 'Các bảng kê chi tiết các nguồn lực sản xuất ưu tiên cho ""%1""';
							|ru = 'Вытесняющие спецификации для ""%1""';
							|en = 'Preemptive bills of materials for ""%1""'; fa = 'Preemptive bills of materials for ""%1""';
							|it = 'Specifiche soppiantate per ""%1""';
							|pl = 'Specyfikacje wypierające dla ""%1""';
							|tr = '""%1"" için yerine geçen ürün reçeteleri'"), CallParameters.BillOfMaterials);
	GenerateListOfPreemptiveSpecifications();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write_BillsOfMaterials" Then
		
		GenerateListOfPreemptiveSpecifications();
		
	EndIf;

EndProcedure

#EndRegion

#Region TableEventHandlersPreemptiveBOM

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateData1(Command)
	
	GenerateListOfPreemptiveSpecifications();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateListOfPreemptiveSpecifications()
	BOMList = Catalogs.BillsOfMaterials.ListOfPreemptiveSpecifications(CallParameters.BillOfMaterials, CallParameters);
	
	CommonClientServer.SetDynamicListParameter(
		PreemptiveBOM,
		"BOMList",
		BOMList);
	Return; // empty handler
	
EndProcedure

#EndRegion