
import React from 'react';
import { Module, User } from '../types';

interface SidebarProps {
  activeModule: Module;
  onModuleChange: (module: Module) => void;
  user: User;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeModule, onModuleChange, user }) => {
  const navItems = [
    { id: 'dashboard', label: 'Painel', icon: 'dashboard' },
    { id: 'recebimento', label: 'Recebimento', icon: 'input' },
    { id: 'movimentacoes', label: 'Movimentações', icon: 'swap_horiz' },
    { id: 'estoque', label: 'Estoque', icon: 'inventory_2' },
    { id: 'expedicao', label: 'Expedição', icon: 'local_shipping' },
    { id: 'inventario_ciclico', label: 'Inventário Cíclico', icon: 'published_with_changes' },
    { id: 'compras', label: 'Pedido de Compras', icon: 'shopping_cart_checkout' },
    { id: 'cadastro', label: 'Cadastro Geral', icon: 'app_registration' },
    { id: 'relatorios', label: 'Relatórios', icon: 'analytics' },
  ] as const;

  const filteredNavItems = navItems.filter(item => user.modules?.includes(item.id as Module));

  return (
    <aside className="w-64 border-r border-[#dbe0e6] dark:border-[#2d3748] bg-white dark:bg-[#1a222c] flex flex-col hidden lg:flex flex-shrink-0 h-full">
      <div className="p-6 flex flex-col gap-2">
        <img src={`${import.meta.env.BASE_URL}norte_tech_logo.png`} alt="Norte Tech Logo" className="h-16 object-contain w-fit" />
        <p className="text-[#617589] text-[10px] font-bold uppercase tracking-widest ml-1">Armazém 028</p>
      </div>

      <nav className="flex-1 px-4 py-4 space-y-2 overflow-y-auto">
        {filteredNavItems.map((item) => {
          const isActive = activeModule === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onModuleChange(item.id)}
              className={`w-full group flex items-center px-4 py-3 rounded-2xl transition-all duration-300 active:scale-[0.98] ${isActive
                ? 'bg-primary text-white shadow-xl shadow-primary/20'
                : 'text-[#617589] hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:text-primary'
                }`}
            >
              <div className="flex items-center w-full">
                <span className="text-[11px] font-black uppercase tracking-[0.08em] text-center flex-1 pr-2">
                  {item.label}
                </span>
              </div>
            </button>
          );
        })}
      </nav>

      <div className="p-6 mt-auto border-t border-[#dbe0e6] dark:border-[#2d3748]">
        <button
          onClick={() => onModuleChange('configuracoes')}
          className={`w-full flex items-center px-4 py-4 rounded-2xl transition-all duration-300 active:scale-[0.98] ${activeModule === 'configuracoes'
            ? 'bg-slate-900 text-white shadow-xl'
            : 'text-[#617589] hover:bg-slate-50 dark:hover:bg-slate-800/50 hover:text-slate-900 dark:hover:text-white'
            }`}
        >
          <div className="flex items-center w-full">
            <span className="text-[11px] font-black uppercase tracking-[0.08em] text-center flex-1 pr-2">
              Configurações
            </span>
          </div>
        </button>
      </div>
    </aside>
  );
};
