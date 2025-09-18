function m_db=lin_space_mean(db_val)

    m_db=10*log10(mean(10.^(db_val/10)));

end