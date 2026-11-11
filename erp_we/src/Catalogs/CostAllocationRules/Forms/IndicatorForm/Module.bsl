#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Object.AssignRule = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter Then
		Title = NStr("vi = 'Chỉ tiêu phân bổ giữa các đối tượng phát sinh chi phí';
					|ru = 'Показатель распределения между объектами возникновения затрат';
					|en = 'Indicator for allocating expenses between cost centers'; fa = 'Indicator for allocating expenses between cost centers';
					|it = 'Indicatore di distribuzione tra i centri di costo';
					|pl = 'Wskaźnik podziału między obiektami tworzenia się rozchodów';
					|tr = 'Gider oluşumu nesneleri arasındaki dağıtım göstergesi'", Common.DefaultLanguageCode()); 
	Else
		Title = NStr("vi = 'Chỉ tiêu phân bổ giữa các bộ phận';
					|ru = 'Показатель распределения между подразделениями';
					|en = 'Indicator for allocation between business units'; fa = 'Indicator for allocation between business units';
					|it = 'Indicatore della ripartizione tra i reparti';
					|pl = 'Wskaźnika podziału między działami';
					|tr = 'Departmanlar arasındaki dağıtım göstergesi'", Common.DefaultLanguageCode());
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	ObjectAttributesLock.LockAttributes(ThisForm);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelEditMetricValuesClick(Item)
	
	If Not ValueIsFilled(Object.Ref) Then
		WarningText =  NStr("vi = 'Trước khi nhập giá trị, cần ghi lại chỉ tiêu';
							|ru = 'Перед вводом значений показатель требуется записать';
							|en = 'Save the indicator before entering values'; fa = 'Save the indicator before entering values';
							|it = 'Перед вводом значений показатель требуется записать';
							|pl = 'Save the indicator before entering values';
							|tr = 'Değerleri girmeden önce göstergenin kaydedilmesi gerekir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Factor", Object.Ref);
	FormParameters.Insert("OnlyValues");
	FormParameters.Insert("AssignRule", Object.AssignRule);
	
	OpenForm("Catalog.CostAllocationRules.Form.ListFormManually",
						FormParameters,
						ThisForm,
						,,,,
						FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
