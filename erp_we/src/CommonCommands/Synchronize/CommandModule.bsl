///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not DataExchangeServerCall.SUBAssetIsIncludedInDSLExchangePlans(CommandParameter) Then
		
		Text = NStr("vi = 'Lệnh không được dùng cho kiểu nút này';
					|ru = 'Команда не предназначена для данного типа узлов';
					|en = 'The command is not intended for this node type'; fa = 'The command is not intended for this node type';
					|it = 'Команда не предназначена для данного типа узлов';
					|pl = 'The command is not intended for this node type';
					|tr = 'Komut bu tür düğümlere yönelik değildir'",
			CommonClient.DefaultLanguageCode());
		ShowMessageBox(, Text);
		
		Return;
	
	EndIf;
	
	DataExchangeClient.ExecuteDataExchangeCommandProcessing(CommandParameter, CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion
