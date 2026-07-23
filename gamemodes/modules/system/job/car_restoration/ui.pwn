//-----------------------------------------------------------------------------
// Car restoration job - recruitment, contracts and employee dialogs
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

stock Restore_GetRankName(level, destination[], size)
{
    switch (level)
    {
        case 1: format(destination, size, "Phu viec ky thuat");
        case 2: format(destination, size, "Ky thuat vien bac 1");
        case 3: format(destination, size, "Ky thuat vien bac 2");
        case 4: format(destination, size, "Ky thuat vien cao cap");
        default: format(destination, size, "Chuyen gia phuc che");
    }
    return 1;
}

stock Restore_ShowApplication(playerid)
{
    new body[2048];

    format(
        body,
        sizeof(body),
        "{F5A623}LOS SANTOS RESTORATION - PHONG NHAN SU\n\n\
{FFFFFF}Vi tri: {FFD54F}Ky thuat vien phuc che xe\n\
{FFFFFF}Dia diem: {E0E0E0}Temple, Los Santos\n\
{FFFFFF}Hinh thuc: {E0E0E0}Nhan hop dong theo ca\n\n\
{F5A623}NOI DUNG CONG VIEC\n\
{FFFFFF}- Nhan mot trong ba don phuc che tu dai ly.\n\
- Kiem tra xe va sua theo tung cong doan.\n\
- Hoan thanh chuoi thao tac ky nang Y, N va C.\n\
- Chay thu xe va ban giao dung dia diem.\n\
- Giu xe hop dong an toan trong suot ca lam.\n\n\
{F5A623}CHE DO NHAN VIEN\n\
{FFFFFF}Luong co ban: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap dung cu: {66BB6A}$%d/ngay\n\
{FFFFFF}Tien cong: {E0E0E0}Thanh toan sau moi bo phan\n\
{BDBDBD}Luong ngay va phu cap se ket noi Payday sau.\n\n\
Nhan \"Nop ho so\" de dang ky lam viec.",
        RESTORE_DAILY_SALARY,
        RESTORE_DAILY_ALLOWANCE
    );

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_APPLICATION,
        DIALOG_STYLE_MSGBOX,
        "Los Santos Restoration - Ho so xin viec",
        body,
        "Nop ho so",
        "Dong"
    );
    return 1;
}

stock Restore_ShowEmployeeMenu(playerid)
{
    new contractStatus[48];

    if (Restore_IsOnContract(playerid))
    {
        new stageName[36];
        Restore_GetStageName(
            s_RestoreContractStage[playerid],
            stageName,
            sizeof(stageName)
        );
        format(
            contractStatus,
            sizeof(contractStatus),
            "%s",
            stageName
        );
    }
    else
    {
        format(contractStatus, sizeof(contractStatus), "San sang");
    }

    new body[768];
    format(
        body,
        sizeof(body),
        "Muc\tTrang thai\n\
Ho so ky thuat vien\tThong tin nhan vien\n\
Hop dong phuc che\t%s\n\
Huong dan cong viec\tQuy trinh 5 cong doan\n\
Huy hop dong hien tai\t%s\n\
Xin nghi viec\tCham dut hop dong",
        contractStatus,
        Restore_IsOnContract(playerid) ?
            "Dang co hop dong" : "Khong co hop dong"
    );

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_EMPLOYEE_MENU,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Los Santos Restoration - Cong nhan vien",
        body,
        "Chon",
        "Dong"
    );
    return 1;
}

stock Restore_ShowEmployeeProfile(playerid)
{
    new
        body[2048],
        rankName[36],
        stageName[40],
        vehicleStatus[80];

    new const level = Job_GetLevel(
        playerid,
        JOB_CAR_RESTORATION
    );
    new const nextXP = Job_GetNextLevelExperience(level);

    Restore_GetRankName(level, rankName, sizeof(rankName));
    Restore_GetStageName(
        s_RestoreContractStage[playerid],
        stageName,
        sizeof(stageName)
    );

    if (Restore_IsOnContract(playerid))
    {
        format(
            vehicleStatus,
            sizeof(vehicleStatus),
            "%s - khoang sua %d",
            g_RestoreModels[s_RestoreContractModel[playerid]][
                RESTORE_MODEL_NAME
            ],
            s_RestoreVehicleBay[playerid] + 1
        );
    }
    else
    {
        format(
            vehicleStatus,
            sizeof(vehicleStatus),
            "Chua nhan xe"
        );
    }

    format(
        body,
        sizeof(body),
        "{F5A623}HO SO KY THUAT VIEN\n\n\
{FFFFFF}Ma nhan vien: {FFD54F}LSR-%06d\n\
{FFFFFF}Ten nhan vien: {FFD54F}%s\n\
{FFFFFF}Chuc danh: {E0E0E0}%s\n\
{FFFFFF}Ngay nhan viec: {E0E0E0}%s\n\
{FFFFFF}Tinh trang: {66BB6A}Dang lam viec\n\n\
{F5A623}LUONG VA PHU CAP\n\
{FFFFFF}Luong co ban: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap dung cu: {66BB6A}$%d/ngay\n\
{FFFFFF}Ky thanh toan: {FFB74D}Cho he thong Payday\n\n\
{F5A623}NANG LUC NGHE NGHIEP\n\
{FFFFFF}Cap nghe: {FFD54F}%d/%d\n\
{FFFFFF}Kinh nghiem: {FFD54F}%d%s\n\
{FFFFFF}Xe da ban giao: {E0E0E0}%d\n\
{FFFFFF}Bo phan da sua: {E0E0E0}%d\n\
{FFFFFF}Streak tot nhat: {E0E0E0}%d\n\
{FFFFFF}Tong thu nhap nghe: {66BB6A}$%d\n\n\
{F5A623}HOP DONG HIEN TAI\n\
{FFFFFF}Xe: {E0E0E0}%s\n\
{FFFFFF}Cong doan: {E0E0E0}%s\n\
{FFFFFF}Thu nhap ca: {66BB6A}$%d",
        GetPlayerCharacterID(playerid),
        s_CharacterName[playerid],
        rankName,
        pJobHiredAt[playerid][0] ?
            pJobHiredAt[playerid] : "Chua co",
        pJobSalary[playerid],
        pJobAllowance[playerid],
        level,
        MAX_JOB_LEVEL,
        s_PlayerJobExperience[playerid][JOB_CAR_RESTORATION],
        nextXP > 0 ? "" : " (toi da)",
        s_PlayerJobCompletedRuns[playerid][JOB_CAR_RESTORATION],
        s_PlayerJobCompletedTasks[playerid][
            JOB_CAR_RESTORATION
        ],
        s_PlayerJobBestStreak[playerid][JOB_CAR_RESTORATION],
        s_PlayerJobTotalEarnings[playerid][JOB_CAR_RESTORATION],
        vehicleStatus,
        stageName,
        s_PlayerJobShiftEarnings[playerid]
    );

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_PROFILE,
        DIALOG_STYLE_MSGBOX,
        "Los Santos Restoration - Ho so nhan vien",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock Restore_ShowGuide(playerid)
{
    new const body[] =
        "{F5A623}SO TAY PHUC CHE XE\n\n\
{FFFFFF}1. Gap quan doc xuong va nhan {FFD54F}Y{FFFFFF}.\n\
2. Mo \"Hop dong phuc che\" va chon mot trong ba don.\n\
3. Den khoang sua duoc chi dinh, lai gan xe va nhan {FFD54F}Y{FFFFFF}.\n\
4. Hoan thanh chuoi ba phim {FFD54F}Y, N hoac C{FFFFFF}.\n\
5. Moi bo phan hoan thanh se duoc tra tien va XP ngay.\n\
6. Quy trinh gom: kiem tra, lop, dong co, than vo va dien.\n\
7. Sau khi sua xong, lai chinh xe hop dong den dai ly.\n\
8. Tai checkpoint ban giao, ngoi ghe lai va nhan {FFD54F}Y{FFFFFF}.\n\n\
{FFB74D}QUY TAC CHONG GAY NAN\n\
{FFFFFF}- Bam sai chi khoi dong lai chuoi phim, khong mat tien.\n\
- Het thoi gian chi can nhan Y de thu lai cong doan.\n\
- Xe bi va quet khi chay thu van duoc ban giao, nhung giam thuong chat luong.\n\
- Dung /job quit de huy ca bat ky luc nao, thanh tich cu van duoc luu.";

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_GUIDE,
        DIALOG_STYLE_MSGBOX,
        "Los Santos Restoration - Huong dan",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock Restore_ShowContractOffers(playerid)
{
    if (!Restore_IsEmployee(playerid))
    {
        return Restore_ShowApplication(playerid);
    }

    if (Restore_IsOnContract(playerid))
    {
        Restore_ShowCurrentStage(playerid);
        return Restore_ShowEmployeeProfile(playerid);
    }

    if (!Restore_GenerateOffers(playerid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Khong the tao danh sach hop dong luc nay.",
            4000
        );
        return 0;
    }

    new body[1024];
    format(
        body,
        sizeof(body),
        "Xe\tDo kho\tBan giao\tThu nhap du kien\n"
    );

    for (new offer = 0; offer < RESTORE_MAX_OFFERS; offer++)
    {
        new const modelIndex =
            s_RestoreOfferModel[playerid][offer];
        new const delivery =
            s_RestoreOfferDelivery[playerid][offer];
        new const difficulty =
            g_RestoreModels[modelIndex][
                RESTORE_MODEL_DIFFICULTY
            ];

        new difficultyName[20], line[224];
        Restore_GetDifficultyName(
            difficulty,
            difficultyName,
            sizeof(difficultyName)
        );

        new const estimatedPay =
            Restore_GetFinalPay(difficulty) +
            (Restore_GetPartPay(difficulty) * 5);

        format(
            line,
            sizeof(line),
            "%s\t%s\t%s\t$%d\n",
            g_RestoreModels[modelIndex][RESTORE_MODEL_NAME],
            difficultyName,
            g_RestoreDeliveryPoints[delivery][
                RESTORE_DELIVERY_NAME
            ],
            estimatedPay
        );
        strcat(body, line, sizeof(body));
    }

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_CONTRACTS,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Los Santos Restoration - Don tu dai ly",
        body,
        "Nhan don",
        "Quay lai"
    );
    return 1;
}

stock Restore_ShowCancelConfirmation(playerid)
{
    if (!Restore_IsOnContract(playerid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban khong co hop dong phuc che dang hoat dong.",
            4000
        );
        return Restore_ShowEmployeeMenu(playerid);
    }

    new const body[] =
        "{F5A623}XAC NHAN HUY HOP DONG\n\n\
{FFFFFF}- Xe dang phuc che se duoc thu hoi.\n\
- Tien va XP cua cac bo phan da sua van duoc giu.\n\
- Khong co phi phat va khong mat thanh tich cu.\n\
- Hop dong nay se khong duoc tinh la xe da ban giao.\n\n\
Ban co chac muon huy hop dong hien tai?";

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_CANCEL,
        DIALOG_STYLE_MSGBOX,
        "Los Santos Restoration - Huy hop dong",
        body,
        "Huy hop dong",
        "Quay lai"
    );
    return 1;
}

stock Restore_ShowResignConfirmation(playerid)
{
    new const body[] =
        "{F5A623}XAC NHAN XIN NGHI VIEC\n\n\
{FFFFFF}- Hop dong dang lam se bi huy va xe duoc thu hoi.\n\
- XP, so xe ban giao va tong thu nhap cu van duoc giu.\n\
- Luong va phu cap tren ho so se duoc xoa.\n\n\
Ban co chac muon nghi viec tai xuong?";

    ShowPlayerDialog(
        playerid,
        RESTORE_DIALOG_RESIGN,
        DIALOG_STYLE_MSGBOX,
        "Los Santos Restoration - Xin nghi viec",
        body,
        "Nghi viec",
        "Quay lai"
    );
    return 1;
}

stock Restore_HireEmployee(playerid)
{
    if (!pJobLoaded[playerid])
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ho so cong viec dang tai. Hay thu lai sau giay lat.",
            4000
        );
        return 0;
    }

    if (pJob[playerid] != JOB_NONE)
    {
        if (pJob[playerid] == JOB_CAR_RESTORATION)
        {
            return Restore_ShowEmployeeMenu(playerid);
        }

        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Nhan vat dang co mot cong viec khac. Hay nghi viec truoc.",
            4500
        );
        return 0;
    }

    new year, month, day, hour, minute, second;
    getdate(year, month, day);
    gettime(hour, minute, second);

    pJob[playerid] = JOB_CAR_RESTORATION;
    pJobSalary[playerid] = RESTORE_DAILY_SALARY;
    pJobAllowance[playerid] = RESTORE_DAILY_ALLOWANCE;

    format(
        pJobHiredAt[playerid],
        sizeof(pJobHiredAt[]),
        "%04d-%02d-%02d %02d:%02d:%02d",
        year,
        month,
        day,
        hour,
        minute,
        second
    );

    new query[512];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `job`=%d,`job_hired_at`=CURRENT_TIMESTAMP,`job_salary`=%d,`job_allowance`=%d WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        JOB_CAR_RESTORATION,
        RESTORE_DAILY_SALARY,
        RESTORE_DAILY_ALLOWANCE,
        GetPlayerCharacterID(playerid),
        GetPlayerAccountID(playerid)
    );
    mysql_tquery(g_DatabaseHandle, query);

    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        "Ho so da duoc duyet. Ban co the nhan don phuc che ngay.",
        5500
    );
    Restore_ShowEmployeeProfile(playerid);
    return 1;
}

stock Restore_ResignEmployee(playerid)
{
    if (!Restore_IsEmployee(playerid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban khong co hop dong lao dong tai xuong.",
            4000
        );
        return 0;
    }

    if (Job_IsActive(playerid, JOB_CAR_RESTORATION))
    {
        Job_Stop(playerid, JOB_STOP_QUIT);
    }
    else if (Restore_HasContractVehicle(playerid))
    {
        Restore_DestroyContractVehicle(playerid);
    }

    pJob[playerid] = JOB_NONE;
    pJobHiredAt[playerid][0] = 0;
    pJobSalary[playerid] = 0;
    pJobAllowance[playerid] = 0;

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `job`=0,`job_hired_at`=NULL,`job_salary`=0,`job_allowance`=0 WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        GetPlayerCharacterID(playerid),
        GetPlayerAccountID(playerid)
    );
    mysql_tquery(g_DatabaseHandle, query);

    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        "Da cham dut hop dong. Thanh tich phuc che cu van duoc luu.",
        5000
    );
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    switch (dialogid)
    {
        case RESTORE_DIALOG_APPLICATION:
        {
            if (response)
            {
                Restore_HireEmployee(playerid);
            }
            return 1;
        }

        case RESTORE_DIALOG_EMPLOYEE_MENU:
        {
            if (!response)
            {
                return 1;
            }

            switch (listitem)
            {
                case 0: Restore_ShowEmployeeProfile(playerid);
                case 1: Restore_ShowContractOffers(playerid);
                case 2: Restore_ShowGuide(playerid);
                case 3: Restore_ShowCancelConfirmation(playerid);
                case 4: Restore_ShowResignConfirmation(playerid);
            }
            return 1;
        }

        case RESTORE_DIALOG_PROFILE, RESTORE_DIALOG_GUIDE:
        {
            if (response)
            {
                Restore_ShowEmployeeMenu(playerid);
            }
            return 1;
        }

        case RESTORE_DIALOG_CONTRACTS:
        {
            if (response)
            {
                Restore_AcceptOffer(playerid, listitem);
            }
            else
            {
                Restore_ShowEmployeeMenu(playerid);
            }
            return 1;
        }

        case RESTORE_DIALOG_CANCEL:
        {
            if (response)
            {
                if (Job_IsActive(
                        playerid,
                        JOB_CAR_RESTORATION
                    ))
                {
                    Job_Stop(playerid, JOB_STOP_QUIT);
                    ShowNotifyText(
                        playerid,
                        NOTIFY_TYPE_MODERN,
                        "Hop dong da huy. Tien cac bo phan da sua van duoc giu.",
                        5000
                    );
                }
            }
            else
            {
                Restore_ShowEmployeeMenu(playerid);
            }
            return 1;
        }

        case RESTORE_DIALOG_RESIGN:
        {
            if (response)
            {
                Restore_ResignEmployee(playerid);
            }
            else
            {
                Restore_ShowEmployeeMenu(playerid);
            }
            return 1;
        }
    }
    return 0;
}
