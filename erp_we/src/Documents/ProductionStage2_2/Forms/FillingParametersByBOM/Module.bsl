
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, Parameters,
		"UseFinishedProducts, UseLaborCosts, UseWorkCenterTypes");
	
	Items.FillInOutputItems.Visible = UseFinishedProducts;
	Items.FillInTheLaborCosts.Visible = UseLaborCosts;
	Items.FillInTheTypesOfWorkCenters.Visible = UseWorkCenterTypes;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Fill(Command)
	
	If Not FillInTheProvisionOfMaterialsAndWorks
		And Not FillInOutputItems
		And Not FillInByProducts
		And Not FillInTheLaborCosts
		And Not FillInTheTypesOfWorkCenters Then
		
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Không có phần bảng được chọn để điền';
				|ru = 'Не выбраны табличные части для заполнения';
				|en = 'Tables for filling in is not selected'; fa = 'Tables for filling in is not selected';
				|it = 'Le tabelle da compilare non sono state selezionate';
				|pl = 'Nie wybrano sekcji tabelaryczne do wypełnienia';
				|tr = 'Doldurulacak tablo bölümleri seçilmedi'"));
		Return;
		
	EndIf;
	
	Result = New Structure;
	If FillInTheProvisionOfMaterialsAndWorks Then
		Result.Insert("SupplyWithMaterialsAndWorks");
	EndIf;
	If UseFinishedProducts
			And FillInOutputItems Then
		Result.Insert("ManufacturedProducts");
	EndIf;
	If FillInByProducts Then
		Result.Insert("SideAndIntermediateRelease");
	EndIf;
	If UseLaborCosts
			And FillInTheLaborCosts Then
		Result.Insert("LaborCosts");
	EndIf;
	If UseWorkCenterTypes
			And FillInTheTypesOfWorkCenters Then
		Result.Insert("WorkCenterTypes");
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	FillInTheProvisionOfMaterialsAndWorks = True;
	FillInOutputItems = True;
	FillInByProducts = True;
	FillInTheLaborCosts = True;
	FillInTheTypesOfWorkCenters = True;
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	FillInTheProvisionOfMaterialsAndWorks = False;
	FillInOutputItems = False;
	FillInByProducts = False;
	FillInTheLaborCosts = False;
	FillInTheTypesOfWorkCenters = False;
	
EndProcedure

#EndRegion
