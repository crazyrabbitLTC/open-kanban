import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BigNumber } from "ethers";
import { string } from "hardhat/internal/core/params/argumentTypes";

import type { Board } from "../types/contracts/Board";
import type { DB } from "../types/contracts/DB";
import type { Manager } from "../types/contracts/Manager";

type Fixture<T> = () => Promise<T>;

declare module "mocha" {
  export interface Context {
    board: Board;
    db: DB;
    manager: Manager;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
    manager_init_params: ManagerInitParams;
  }
}

export interface Signers {
  admin: SignerWithAddress;
  manager: SignerWithAddress;
  noRoles: SignerWithAddress;
}

export interface Ticket {
  id: number;
  name: string;
  uri: string;
  columnId: BigNumber;
  statusId: number;
  data: string;
}

export interface Column {
  name: string;
  uri: string;
  database: string;
  data: string;
}

export interface Status {
  name: string;
  uri: string;
  data: string;
}

export interface UserWithRoles {
  account: string;
  uri: string;
  roles: string[];
  data: string;
}

export interface Kanban {
  name: string;
  description: string;
  uri: string;
  data: string;
}

export interface ManagerInitParams {
  superAdmin: string;
  databaseImplementation: string;
  boardImplementation: string;
  usersWithRoles: UserWithRoles[];
  statusLevels: Status[];
  columns: Column[];
  kanban: Kanban;
}
